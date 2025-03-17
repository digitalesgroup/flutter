// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../routes.dart';
import '../app_theme.dart';
import 'home_screen.dart';
import 'client_screens.dart';
import 'appointment_screens.dart';
import 'financial_screens.dart';
import 'admin_screens.dart';
import 'client_metrics_screen.dart';
import 'appointment_metrics_screen.dart';
import 'therapist_metrics_screen.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  int _totalCitas = 0;

  // Menú lateral actualizado con la nueva sección de Métricas
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Inicio'},
    {'icon': Icons.people, 'title': 'Clientes'},
    {'icon': Icons.analytics, 'title': 'Métricas Clientes'},
    {'icon': Icons.calendar_today, 'title': 'Agenda'},
    {'icon': Icons.assessment, 'title': 'Citas'},
    {'icon': Icons.spa, 'title': 'Análisis Terapeutas'},
    {'icon': Icons.attach_money, 'title': 'Reportes'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Get current user
      final user = authService.currentUser;
      if (user != null) {
        // Load user data from Firestore
        final userData = await dbService.getUser(user.uid);

        // Cargar citas para hoy
        final appointments =
            await dbService.getAppointmentsByDate(DateTime.now());

        setState(() {
          _currentUser = userData;
          _totalCitas = appointments.length;
          _isLoading = false;
        });
      } else {
        // Not logged in, go to login screen
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, navigationState, child) {
        return Scaffold(
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    // Menú lateral
                    NavigationRail(
                      selectedIndex: navigationState.selectedIndex,
                      extended: MediaQuery.of(context).size.width > 900,
                      minWidth: 60,
                      minExtendedWidth: 220,
                      backgroundColor: AppTheme.primaryColor,
                      selectedIconTheme:
                          const IconThemeData(color: Colors.white),
                      unselectedIconTheme:
                          IconThemeData(color: Colors.white.withOpacity(0.7)),
                      selectedLabelTextStyle:
                          const TextStyle(color: Colors.white),
                      unselectedLabelTextStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                      onDestinationSelected: (int index) {
                        // Actualizamos mediante el gestor de estado
                        Provider.of<NavigationState>(context, listen: false)
                            .setSelectedIndex(index);
                      },
                      leading: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: MediaQuery.of(context).size.width > 900
                            ? Row(
                                children: [
                                  const Icon(Icons.spa,
                                      color: Colors.white, size: 30),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Meu Tempo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(Icons.spa,
                                color: Colors.white, size: 30),
                      ),
                      destinations: _menuItems.map((item) {
                        return NavigationRailDestination(
                          icon: Icon(item['icon']),
                          selectedIcon: Icon(item['icon']),
                          label: Text(item['title']),
                        );
                      }).toList(),
                    ),

                    // Contenido principal
                    Expanded(
                      child: _buildMainContent(navigationState),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMainContent(NavigationState navigationState) {
    // Si estamos en una vista de detalle, mostrar el contenido correspondiente
    if (navigationState.isInDetailView) {
      // Según el tipo de detalle, mostrar la pantalla correspondiente
      switch (navigationState.currentDetailType) {
        case 'client':
          return ClientDetailsScreen(
            clientId: navigationState.currentDetailId,
            onEditSelected: (clientId) {
              // Navegar a la pantalla de edición manteniendo el dashboard
              Provider.of<NavigationState>(context, listen: false)
                  .navigateToDetail('client_edit', clientId);
            },
          );
        case 'client_edit':
          return ClientEditScreen(
            clientId: navigationState.currentDetailId,
          );
        case 'appointment':
          return AppointmentDetailsScreen(
            appointmentId: navigationState.currentDetailId,
          );
        default:
          return const Center(child: Text('Tipo de detalle no reconocido'));
      }
    }

    // Si no estamos en detalle, mostramos la pantalla principal según el índice seleccionado
    switch (navigationState.selectedIndex) {
      case 0:
        return HomeScreen();
      case 1:
        return ClientListScreen(
          onClientSelected: (clientId) {
            // Al seleccionar un cliente, navegamos a sus detalles
            Provider.of<NavigationState>(context, listen: false)
                .navigateToDetail('client', clientId);
          },
        );
      case 2:
        return ClientMetricsScreen();
      case 3:
        return AppointmentListScreen(
          onAppointmentSelected: (appointmentId) {
            Provider.of<NavigationState>(context, listen: false)
                .navigateToDetail('appointment', appointmentId);
          },
        );
      case 4:
        return AppointmentMetricsScreen();
      case 5:
        return TherapistMetricsScreen();
      case 6:
        return FinancialDashboardScreen(initialTab: 0);
      default:
        return HomeScreen();
    }
  }
}
