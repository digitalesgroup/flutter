//lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../routes.dart';
import '../models/appointment_model.dart';
import '../app_theme.dart';
import '../widgets/responsive_layout.dart'; // Importamos el nuevo widget responsivo

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  List<dynamic> _todaysAppointments = [];
  bool _isLoading = true;
  double _dailyRevenue = 0.0;
  int _totalClients = 0;

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

        // Load today's appointments
        final appointments = await dbService.getAppointmentsByDate(
          DateTime.now(),
        );

        // If user is a therapist, filter appointments for this therapist
        List<dynamic> userAppointments = appointments;
        if (userData.role == UserRole.therapist) {
          userAppointments =
              appointments.where((a) => a.employeeId == user.uid).toList();
        }

        // Load client details for appointments
        List<dynamic> appointmentsWithClients = [];
        for (var appointment in userAppointments) {
          final client = await dbService.getUser(appointment.clientId);
          appointmentsWithClients.add({
            'appointment': appointment,
            'client': client,
          });
        }

        // Load clients count
        final clients = await dbService.getClients();

        // Load monthly financial data
        final now = DateTime.now();
        final dailySummary = await dbService.getDailyFinancialSummary(now);

        setState(() {
          _currentUser = userData;
          _todaysAppointments = appointmentsWithClients;
          _totalClients = clients.length;
          _dailyRevenue = dailySummary['totalPayments'] ?? 0.0;
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

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _currentUser == null
            ? const Center(child: Text('Usuario no encontrado'))
            : ResponsiveLayout(
                mobileLayout: _buildMobileLayout(),
                tabletLayout: _buildTabletLayout(),
                desktopLayout: _buildDesktopLayout(),
              );
  }

  // Layout para móviles (diseño en una sola columna)
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de bienvenida
        _buildWelcomeCard(),

        // Contenido scrollable
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas (una debajo de otra en móvil)
                  _buildStatCard(Icons.people, Colors.blue, 'Clientes',
                      _totalClients.toString(),
                      isFullWidth: true),
                  const SizedBox(height: 12),
                  _buildStatCard(Icons.calendar_today, Colors.orange,
                      'Citas Hoy', _todaysAppointments.length.toString(),
                      isFullWidth: true),
                  const SizedBox(height: 12),
                  _buildStatCard(Icons.attach_money, Colors.green,
                      'Ingresos Hoy', '\$${_dailyRevenue.toStringAsFixed(0)}',
                      isFullWidth: true),

                  const SizedBox(height: 24),

                  // Acciones Rápidas
                  _buildSectionTitle('Acciones Rápidas'),
                  const SizedBox(height: 16),

                  // En móvil, 2 acciones por fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Nuevo Cliente',
                          Icons.person_add,
                          Colors.blue,
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.clientAdd),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          'Nueva Cita',
                          Icons.calendar_today,
                          Colors.orange,
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.appointmentAdd),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Ver Clientes',
                          Icons.people,
                          Colors.purple,
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.clients),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          'Transacción',
                          Icons.add_circle,
                          Colors.green,
                          () => Navigator.of(context).pushNamed(
                              AppRoutes.financial,
                              arguments: {'initialTab': 2}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Citas de Hoy
                  _buildSectionTitle(
                      'Citas de Hoy (${_todaysAppointments.length})'),
                  const SizedBox(height: 16),

                  // Lista de citas (versión móvil simplificada)
                  _todaysAppointments.isEmpty
                      ? _buildEmptyAppointmentsMessage()
                      : Column(
                          children: _todaysAppointments
                              .map((data) => _buildAppointmentCardMobile(data))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout para tablets (diseño intermedio)
  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de bienvenida
        _buildWelcomeCard(),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas en fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(Icons.people, Colors.blue,
                            'Clientes', _totalClients.toString()),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                            Icons.calendar_today,
                            Colors.orange,
                            'Citas Hoy',
                            _todaysAppointments.length.toString()),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                            Icons.attach_money,
                            Colors.green,
                            'Ingresos Hoy',
                            '\$${_dailyRevenue.toStringAsFixed(0)}'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Acciones Rápidas
                  _buildSectionTitle('Acciones Rápidas'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Nuevo Cliente',
                          Icons.person_add,
                          Colors.blue,
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.clientAdd),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'Nueva Cita',
                          Icons.calendar_today,
                          Colors.orange,
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.appointmentAdd),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'Ver Clientes',
                          Icons.people,
                          Colors.purple,
                          () => Navigator.of(context)
                              .pushNamed(AppRoutes.clients),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'Nueva Transacción',
                          Icons.add_circle,
                          Colors.green,
                          () => Navigator.of(context).pushNamed(
                              AppRoutes.financial,
                              arguments: {'initialTab': 2}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Citas de Hoy
                  _buildSectionTitle(
                      'Citas de Hoy (${_todaysAppointments.length})'),
                  const SizedBox(height: 16),

                  // Tabla de citas
                  _todaysAppointments.isEmpty
                      ? _buildEmptyAppointmentsMessage()
                      : Column(
                          children: [
                            _buildTableHeaders(),
                            const Divider(height: 1),
                            ..._todaysAppointments.asMap().entries.map(
                              (entry) {
                                final index = entry.key;
                                final appointmentData = entry.value;

                                return Column(
                                  children: [
                                    _buildAppointmentRow(appointmentData),
                                    if (index < _todaysAppointments.length - 1)
                                      const Divider(height: 1),
                                  ],
                                );
                              },
                            ).toList(),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout para escritorio (diseño completo)
  Widget _buildDesktopLayout() {
    // Similar al tablet pero con más espaciado y posiblemente una sección adicional
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de bienvenida
        _buildWelcomeCard(),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas en fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(Icons.people, Colors.blue,
                            'Clientes', _totalClients.toString()),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildStatCard(
                            Icons.calendar_today,
                            Colors.orange,
                            'Citas Hoy',
                            _todaysAppointments.length.toString()),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildStatCard(
                            Icons.attach_money,
                            Colors.green,
                            'Ingresos Hoy',
                            '\$${_dailyRevenue.toStringAsFixed(0)}'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Layout de dos columnas para el escritorio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna izquierda: Acciones Rápidas
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Acciones Rápidas'),
                            const SizedBox(height: 20),
                            // Acciones en grid para escritorio
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.3,
                              children: [
                                _buildActionCard(
                                  'Nuevo Cliente',
                                  Icons.person_add,
                                  Colors.blue,
                                  () => Navigator.of(context)
                                      .pushNamed(AppRoutes.clientAdd),
                                ),
                                _buildActionCard(
                                  'Nueva Cita',
                                  Icons.calendar_today,
                                  Colors.orange,
                                  () => Navigator.of(context)
                                      .pushNamed(AppRoutes.appointmentAdd),
                                ),
                                _buildActionCard(
                                  'Ver Clientes',
                                  Icons.people,
                                  Colors.purple,
                                  () => Navigator.of(context)
                                      .pushNamed(AppRoutes.clients),
                                ),
                                _buildActionCard(
                                  'Nueva Transacción',
                                  Icons.add_circle,
                                  Colors.green,
                                  () => Navigator.of(context).pushNamed(
                                      AppRoutes.financial,
                                      arguments: {'initialTab': 2}),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 32),

                      // Columna derecha: Citas de Hoy
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                                'Citas de Hoy (${_todaysAppointments.length})'),
                            const SizedBox(height: 20),

                            // Tabla de citas
                            _todaysAppointments.isEmpty
                                ? _buildEmptyAppointmentsMessage()
                                : Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildTableHeaders(),
                                        const Divider(height: 1),
                                        ..._todaysAppointments
                                            .asMap()
                                            .entries
                                            .map(
                                          (entry) {
                                            final index = entry.key;
                                            final appointmentData = entry.value;

                                            return Column(
                                              children: [
                                                _buildAppointmentRow(
                                                    appointmentData),
                                                if (index <
                                                    _todaysAppointments.length -
                                                        1)
                                                  const Divider(height: 1),
                                              ],
                                            );
                                          },
                                        ).toList(),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      color: AppTheme.primaryColor,
      padding:
          EdgeInsets.all(ResponsiveBreakpoints.isMobile(context) ? 16.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido/a, ${_currentUser!.name}',
            style: TextStyle(
              fontSize: ResponsiveBreakpoints.isMobile(context) ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveBreakpoints.isMobile(context) ? 2 : 4),
          Text(
            'Hoy es ${DateFormat('EEEE, d MMMM, yyyy', 'es').format(DateTime.now())}',
            style: TextStyle(
              fontSize: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveBreakpoints.isMobile(context) ? 6 : 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tienes ${_todaysAppointments.length} citas para hoy',
                style: TextStyle(
                  fontSize: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String title, String value,
      {bool isFullWidth = false}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(
            ResponsiveBreakpoints.isMobile(context) ? 12.0 : 16.0),
        child: isFullWidth
            ? Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize:
                          ResponsiveBreakpoints.isDesktop(context) ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveBreakpoints.isMobile(context) ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: ResponsiveBreakpoints.isMobile(context) ? 100 : 120,
          padding: EdgeInsets.symmetric(
              vertical: ResponsiveBreakpoints.isMobile(context) ? 12.0 : 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: ResponsiveBreakpoints.isMobile(context) ? 20 : 25,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              SizedBox(
                  height: ResponsiveBreakpoints.isMobile(context) ? 10 : 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de cita para móvil (versión resumida)
  Widget _buildAppointmentCardMobile(Map<String, dynamic> appointmentData) {
    final appointment = appointmentData['appointment'];
    final client = appointmentData['client'];

    // Obtener color según el estado
    Color statusColor;
    Color statusBgColor;
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
        break;
      case AppointmentStatus.completed_unpaid:
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.1);
        break;
      case AppointmentStatus.completed_paid:
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.appointmentDetails,
            arguments: {'appointmentId': appointment.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      client.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          appointment.treatmentType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appointment.startTime.format(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaders() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: 12.0, horizontal: isMobile ? 8.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          SizedBox(width: isMobile ? 30 : 40), // Para el avatar
          Expanded(
            flex: 2,
            child: Text(
              'Cliente',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Detalles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          // Opciones de estado - ocultas en móvil
          if (!isMobile)
            Text(
              'Estado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(Map<String, dynamic> appointmentData) {
    final appointment = appointmentData['appointment'];
    final client = appointmentData['client'];
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    // Formato hora
    final startTime = appointment.startTime.format(context);

    // Get status color and background color based on appointment status
    Color statusColor;
    Color statusBgColor;
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withOpacity(0.1);
        break;
      case AppointmentStatus.completed_unpaid:
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.1);
        break;
      case AppointmentStatus.completed_paid:
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.appointmentDetails,
          arguments: {'appointmentId': appointment.id},
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 12.0, horizontal: isMobile ? 8.0 : 16.0),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: isMobile ? 15 : 18,
              backgroundColor: Colors.grey[300],
              child: Text(
                client.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),

            // Cliente
            Expanded(
              flex: 2,
              child: Text(
                client.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: isMobile ? 12 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Detalles
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora: $startTime',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                    ),
                  ),
                  Text(
                    'Tipo: ${appointment.treatmentType}',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Estado
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusText(appointment.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAppointmentsMessage() {
    return Center(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay citas programadas para hoy',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // Helper method for getting text representation of appointment status
  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.completed_unpaid:
        return 'Pendiente de cobro';
      case AppointmentStatus.completed_paid:
        return 'Completada y Pagada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }
}
