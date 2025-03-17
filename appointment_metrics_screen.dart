// lib/screens/appointment_metrics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../routes.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/appointment_widgets.dart';
import 'appointment_screens.dart';

class AppointmentMetricsScreen extends StatefulWidget {
  @override
  _AppointmentMetricsScreenState createState() =>
      _AppointmentMetricsScreenState();
}

class _AppointmentMetricsScreenState extends State<AppointmentMetricsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<AppointmentModel> _allAppointments = [];
  List<UserModel> _therapists = [];
  List<UserModel> _clients = [];

  // Listas filtradas
  List<AppointmentModel> _completedAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];
  List<AppointmentModel> _scheduledAppointments = [];
  List<AppointmentModel> _unpaidAppointments = [];
  List<AppointmentModel> _filteredAppointments = [];

  // Contadores para KPIs
  int _totalScheduled = 0;
  int _totalCompleted = 0;
  int _totalCancelled = 0;
  int _totalUnpaid = 0;
  double _completionRate = 0.0;
  double _cancellationRate = 0.0;

  // Para el filtro de fechas
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  late TabController _tabController;
  String _selectedPeriod = 'Mes';

  // Para filtrado adicional
  String? _selectedTherapistId;
  String? _selectedStatus;

  // Para búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Actualizar fechas según el período seleccionado
  void _updateDateRange(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case 'Semana':
          _startDate = now.subtract(Duration(days: 7));
          _endDate = now;
          break;
        case 'Mes':
          _startDate = now.subtract(Duration(days: 30));
          _endDate = now;
          break;
        case 'Trimestre':
          _startDate = now.subtract(Duration(days: 90));
          _endDate = now;
          break;
        case 'Año':
          _startDate = now.subtract(Duration(days: 365));
          _endDate = now;
          break;
      }
    });

    _loadData();
  }

  // Cargar todos los datos necesarios
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Cargar citas en el rango de fechas seleccionado
      final appointments = await dbService.getAppointmentsBetweenDates(
        _startDate,
        _endDate,
        _selectedTherapistId,
      );

      // Cargar terapeutas y clientes
      final therapists = await dbService.getTherapists();
      final clients = await dbService.getClients();

      setState(() {
        _allAppointments = appointments;
        _therapists = therapists;
        _clients = clients;

        // Filtrar y procesar datos
        _processAppointmentData();

        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos de citas: $e');
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

  // Procesar y filtrar los datos de citas
  void _processAppointmentData() {
    // Reiniciar contadores y listas
    _completedAppointments = [];
    _cancelledAppointments = [];
    _scheduledAppointments = [];
    _unpaidAppointments = [];
    _filteredAppointments = [];
    _totalScheduled = 0;
    _totalCompleted = 0;
    _totalCancelled = 0;
    _totalUnpaid = 0;

    // Aplicar filtro de búsqueda
    List<AppointmentModel> searchFilteredAppointments = _allAppointments;
    if (_searchQuery.isNotEmpty) {
      searchFilteredAppointments = _allAppointments.where((app) {
        // Buscar en el cliente
        final client = _clients.firstWhere(
          (c) => c.id == app.clientId,
          orElse: () => UserModel(
            id: '',
            name: '',
            lastName: '',
            role: UserRole.client,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Buscar en el terapeuta
        final therapist = _therapists.firstWhere(
          (t) => t.id == app.employeeId,
          orElse: () => UserModel(
            id: '',
            name: '',
            lastName: '',
            role: UserRole.therapist,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Verificar si la búsqueda coincide con algún campo relevante
        return client.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            therapist.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            app.treatmentType
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            app.reason.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            DateFormat('dd/MM/yyyy').format(app.date).contains(_searchQuery);
      }).toList();
    }

    // Clasificar citas por estado
    for (final app in searchFilteredAppointments) {
      if (app.status == AppointmentStatus.scheduled) {
        _scheduledAppointments.add(app);
        _totalScheduled++;
      } else if (app.status == AppointmentStatus.completed_paid) {
        _completedAppointments.add(app);
        _totalCompleted++;
      } else if (app.status == AppointmentStatus.cancelled) {
        _cancelledAppointments.add(app);
        _totalCancelled++;
      } else if (app.status == AppointmentStatus.completed_unpaid) {
        _unpaidAppointments.add(app);
        _totalUnpaid++;
      }
    }

    // Actualizar la lista filtrada según el estado seleccionado
    _updateFilteredAppointments();

    // Ordenar listas por fecha (más reciente primero)
    _completedAppointments.sort((a, b) => b.date.compareTo(a.date));
    _cancelledAppointments.sort((a, b) => b.date.compareTo(a.date));
    _scheduledAppointments.sort((a, b) => b.date.compareTo(a.date));
    _unpaidAppointments.sort((a, b) => b.date.compareTo(a.date));
    _filteredAppointments.sort((a, b) => b.date.compareTo(a.date));

    // Calcular tasas
    final totalRelevant = _totalCompleted + _totalCancelled;
    _completionRate =
        totalRelevant > 0 ? (_totalCompleted / totalRelevant) * 100 : 0;
    _cancellationRate =
        totalRelevant > 0 ? (_totalCancelled / totalRelevant) * 100 : 0;
  }

  // Actualizar la lista filtrada según el estado seleccionado
  void _updateFilteredAppointments() {
    if (_selectedStatus == null) {
      // Todas las citas
      _filteredAppointments = [
        ..._completedAppointments,
        ..._scheduledAppointments,
        ..._cancelledAppointments,
        ..._unpaidAppointments,
      ];
    } else if (_selectedStatus == 'Completadas') {
      _filteredAppointments = _completedAppointments;
    } else if (_selectedStatus == 'Canceladas') {
      _filteredAppointments = _cancelledAppointments;
    } else if (_selectedStatus == 'Pendientes de cobro') {
      _filteredAppointments = _unpaidAppointments;
    } else if (_selectedStatus == 'Programadas') {
      _filteredAppointments = _scheduledAppointments;
    }

    // Ordenar por fecha
    _filteredAppointments.sort((a, b) => b.date.compareTo(a.date));
  }

  // Obtener nombre de cliente
  String _getClientName(String clientId) {
    try {
      return _clients.firstWhere((c) => c.id == clientId).fullName;
    } catch (e) {
      return 'Cliente';
    }
  }

  // Obtener nombre de terapeuta
  String _getTherapistName(String therapistId) {
    try {
      return _therapists.firstWhere((t) => t.id == therapistId).fullName;
    } catch (e) {
      return 'Terapeuta';
    }
  }

  // Obtener color según estado
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.completed_unpaid:
        return Colors.orange;
      case AppointmentStatus.completed_paid:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtener nombre de estado
  String _getStatusName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.completed_unpaid:
        return 'Pendiente de pago';
      case AppointmentStatus.completed_paid:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Análisis de Citas',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          // Botón para exportar a PDF/Excel (funcionalidad futura)
          ResponsiveVisibility(
            visibleOnMobile: false,
            child: IconButton(
              icon: Icon(Icons.file_download, color: Colors.white),
              tooltip: 'Exportar datos',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Función de exportación en desarrollo')),
                );
              },
            ),
          ),

          // Botón de recargar
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recargar datos',
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            isScrollable: ResponsiveBreakpoints.isMobile(context),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.8),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            indicator: BoxDecoration(
              color: AppTheme.primaryColor.shade700,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Listado de Citas'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Resumen general (sin barra de filtros)
                _buildSummaryTab(),

                // Tab 2: Listado de citas (con barra de filtros)
                Column(
                  children: [
                    _buildFilterBar(), // Barra de filtros solo en esta pestaña
                    Expanded(
                      child: _buildAppointmentList(
                          _filteredAppointments, 'filtradas'),
                    ),
                  ],
                ),
              ],
            ),
      // Botón flotante para nuevo informe o análisis
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.analytics, color: Colors.white),
        tooltip: 'Ver análisis de terapeutas',
        onPressed: () {
          Navigator.of(context).pushNamed(
            AppRoutes.admin,
          );
        },
      ),
    );
  }

  // Barra de filtros y búsqueda (ahora solo se muestra en la pestaña de Listado)
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 1,
          ),
        ],
      ),
      child: ResponsiveLayout(
        mobileLayout: Column(
          children: [
            _buildSearchField(),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTherapistFilter(),
                  SizedBox(width: 8),
                  _buildStatusFilter(),
                ],
              ),
            ),
          ],
        ),
        tabletLayout: Row(
          children: [
            Expanded(child: _buildSearchField()),
            SizedBox(width: 8),
            _buildTherapistFilter(),
            SizedBox(width: 8),
            _buildStatusFilter(),
          ],
        ),
      ),
    );
  }

  // Campo de búsqueda
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar citas...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _processAppointmentData();
        });
      },
    );
  }

  // Filtro de terapeutas
  Widget _buildTherapistFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: _selectedTherapistId,
        hint: Text('Todos los terapeutas'),
        underline: Container(),
        icon: Icon(Icons.arrow_drop_down),
        onChanged: (String? newValue) {
          setState(() {
            _selectedTherapistId = newValue;
            _loadData();
          });
        },
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('Todos los terapeutas'),
          ),
          ..._therapists.map((therapist) {
            return DropdownMenuItem<String?>(
              value: therapist.id,
              child: Text(therapist.fullName),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Filtro por estado de cita
  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: _selectedStatus,
        hint: Text('Todas las citas'),
        underline: Container(),
        icon: Icon(Icons.arrow_drop_down),
        onChanged: (String? newValue) {
          setState(() {
            _selectedStatus = newValue;
            _updateFilteredAppointments();
          });
        },
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('Todas las citas'),
          ),
          DropdownMenuItem<String?>(
            value: 'Completadas',
            child: Text('Completadas'),
          ),
          DropdownMenuItem<String?>(
            value: 'Programadas',
            child: Text('Programadas'),
          ),
          DropdownMenuItem<String?>(
            value: 'Canceladas',
            child: Text('Canceladas'),
          ),
          DropdownMenuItem<String?>(
            value: 'Pendientes de cobro',
            child: Text('Pendientes de cobro'),
          ),
        ],
      ),
    );
  }

  // Tab de resumen con selector de período integrado
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Período analizado con selector integrado
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Período analizado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Selector de período integrado en la card
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            isDense: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: AppTheme.primaryColor),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _updateDateRange(newValue);
                              }
                            },
                            items: <String>['Semana', 'Mes', 'Trimestre', 'Año']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(_startDate),
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.arrow_forward, size: 20),
                      SizedBox(width: 16),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_endDate),
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // KPIs principales
          ResponsiveRowColumn(
            children: [
              // Total de citas
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.event_note,
                  title: 'Total Citas',
                  value: '${_allAppointments.length}',
                  subtitle: '$_selectedPeriod analizado',
                  color: AppTheme.primaryColor,
                ),
              ),

              // Citas completadas
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.check_circle_outline,
                  title: 'Completadas',
                  value: '$_totalCompleted',
                  subtitle: 'Tasa: ${_completionRate.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ),

              // Citas canceladas
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.cancel_outlined,
                  title: 'Canceladas',
                  value: '$_totalCancelled',
                  subtitle: 'Tasa: ${_cancellationRate.toStringAsFixed(1)}%',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Segunda fila de KPIs
          ResponsiveRowColumn(
            children: [
              // Citas pendientes
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.pending_actions,
                  title: 'Programadas',
                  value: '$_totalScheduled',
                  subtitle: 'Para próximas fechas',
                  color: Colors.blue,
                ),
              ),

              // Citas sin pagar
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.payment,
                  title: 'Pendientes de pago',
                  value: '$_totalUnpaid',
                  subtitle: 'Completadas sin cobrar',
                  color: Colors.orange,
                ),
              ),

              // Ingresos (se podría implementar si tienes los datos)
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.attach_money,
                  title: 'Ingresos estimados',
                  value: 'Ver reportes',
                  subtitle: 'En módulo financiero',
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Citas recientes
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Citas Recientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _tabController.animateTo(1);
                          });
                        },
                        child: Text('Ver todas'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Lista de citas recientes (limitada a 5)
                  if (_allAppointments.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay citas en el período seleccionado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._allAppointments
                        .take(5)
                        .map((app) => _buildAppointmentListItem(app))
                        .toList(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Distribución por tratamiento
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución por Tipo de Tratamiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Mostrar distribución de tratamientos
                  ..._buildTreatmentDistribution(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Recomendaciones personalizadas
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recomendaciones y Observaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Recomendaciones basadas en el análisis
                  _buildRecommendations(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Constructor de tarjetas KPI
  Widget _buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constructor de listas de citas
  Widget _buildAppointmentList(
      List<AppointmentModel> appointments, String type) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No hay citas para mostrar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Prueba a cambiar los filtros',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentListItem(appointment);
      },
    );
  }

  // Elemento de lista de citas
  Widget _buildAppointmentListItem(AppointmentModel appointment) {
    final clientName = _getClientName(appointment.clientId);
    final therapistName = _getTherapistName(appointment.employeeId);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(appointment.status).withOpacity(0.2),
          child: Icon(
            appointment.status == AppointmentStatus.scheduled
                ? Icons.event_available
                : appointment.status == AppointmentStatus.completed_paid
                    ? Icons.check_circle
                    : appointment.status == AppointmentStatus.completed_unpaid
                        ? Icons.payments_outlined
                        : Icons.cancel,
            color: _getStatusColor(appointment.status),
          ),
        ),
        title: Text(
          '${appointment.treatmentType} - ${clientName}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(DateFormat('dd/MM/yyyy').format(appointment.date)),
                SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                    '${appointment.startTime.format(context)} - ${appointment.endTime.format(context)}'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Terapeuta: $therapistName',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            _getStatusName(appointment.status),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: _getStatusColor(appointment.status),
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
        onTap: () {
          // Navegar a los detalles de la cita
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailsScreen(
                appointmentId: appointment.id,
              ),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  // Construir distribución de tratamientos
  List<Widget> _buildTreatmentDistribution() {
    final Map<String, int> treatmentCounts = {};
    for (final app in _allAppointments) {
      final treatmentType = app.treatmentType;
      treatmentCounts[treatmentType] =
          (treatmentCounts[treatmentType] ?? 0) + 1;
    }

    // Ordenar por cantidad (descendente)
    final sortedTreatments = treatmentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTreatments.map((entry) {
      final percentage = _allAppointments.isNotEmpty
          ? (entry.value / _allAppointments.length * 100).toStringAsFixed(1)
          : '0.0';

      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${entry.value} (${percentage}%)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: _allAppointments.isNotEmpty
                  ? entry.value / _allAppointments.length
                  : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Construir recomendaciones basadas en el análisis
  Widget _buildRecommendations() {
    final List<Map<String, dynamic>> recommendations = [];

    // Recomendación sobre tasa de cancelación
    if (_cancellationRate > 15) {
      recommendations.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'text':
            'La tasa de cancelación (${_cancellationRate.toStringAsFixed(1)}%) es elevada. Considera revisar las políticas de cancelación o enviar recordatorios adicionales.',
      });
    }

    // Recomendación sobre pagos pendientes
    if (_totalUnpaid > 0) {
      recommendations.add({
        'icon': Icons.attach_money,
        'color': Colors.orange,
        'text':
            'Tienes $_totalUnpaid ${_totalUnpaid == 1 ? 'cita completada' : 'citas completadas'} pendiente${_totalUnpaid == 1 ? '' : 's'} de pago. Considera darles seguimiento para mejorar el flujo de ingresos.',
      });
    }

    // Si no hay recomendaciones específicas
    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'text':
            'Todos los indicadores se ven bien. Continúa con el buen trabajo y monitorea regularmente las métricas.',
      });
    }

    return Column(
      children: recommendations.map((rec) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(rec['icon'], color: rec['color'], size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['text'],
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Extension necesaria para color.shade700
extension ColorShades on Color {
  Color get shade700 {
    final HSLColor hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
