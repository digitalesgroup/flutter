// lib/screens/therapist_metrics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_theme.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/responsive_layout.dart';

class TherapistMetricsScreen extends StatefulWidget {
  @override
  _TherapistMetricsScreenState createState() => _TherapistMetricsScreenState();
}

class _TherapistMetricsScreenState extends State<TherapistMetricsScreen> {
  bool _isLoading = true;
  List<AppointmentModel> _allAppointments = [];
  List<UserModel> _therapists = [];
  Map<String, Map<String, dynamic>> _therapistsMetrics = {};

  // Para el filtro de fechas
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Mes';

  // Para filtrado
  String? _selectedTherapistId;
  String? _selectedTreatmentType;

  @override
  void initState() {
    super.initState();
    _loadData();
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

      // Cargar terapeutas
      final therapists = await dbService.getTherapists();

      setState(() {
        _allAppointments = appointments;
        _therapists = therapists;

        // Procesar datos para las métricas
        _processTherapistMetrics();

        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
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

  void _processTherapistMetrics() {
    _therapistsMetrics = {};

    // Inicializar métricas para cada terapeuta
    for (final therapist in _therapists) {
      _therapistsMetrics[therapist.id] = {
        'therapist': therapist,
        'totalAppointments': 0,
        'completedAppointments': 0,
        'cancelledAppointments': 0,
        'upcomingAppointments': 0,
        'unpaidAppointments': 0,
        'treatmentTypes': <String, int>{},
        'dayOfWeekDistribution': <int, int>{},
        'averageDuration': 0.0,
        'completionRate': 0.0,
        'cancellationRate': 0.0,
      };
    }

    // Filtrar por tipo de tratamiento si está seleccionado
    List<AppointmentModel> filteredAppointments = _allAppointments;
    if (_selectedTreatmentType != null) {
      filteredAppointments = filteredAppointments
          .where((app) => app.treatmentType == _selectedTreatmentType)
          .toList();
    }

    // Calcular métricas para cada terapeuta
    for (final app in filteredAppointments) {
      final therapistId = app.employeeId;

      // Verificar si el terapeuta existe en nuestros registros
      if (!_therapistsMetrics.containsKey(therapistId)) continue;

      // Incrementar contador total
      _therapistsMetrics[therapistId]!['totalAppointments'] =
          _therapistsMetrics[therapistId]!['totalAppointments'] + 1;

      // Contadores por estado
      if (app.status == AppointmentStatus.completed_paid ||
          app.status == AppointmentStatus.completed_unpaid) {
        _therapistsMetrics[therapistId]!['completedAppointments'] =
            _therapistsMetrics[therapistId]!['completedAppointments'] + 1;

        // Si es sin pagar
        if (app.status == AppointmentStatus.completed_unpaid) {
          _therapistsMetrics[therapistId]!['unpaidAppointments'] =
              _therapistsMetrics[therapistId]!['unpaidAppointments'] + 1;
        }
      } else if (app.status == AppointmentStatus.cancelled) {
        _therapistsMetrics[therapistId]!['cancelledAppointments'] =
            _therapistsMetrics[therapistId]!['cancelledAppointments'] + 1;
      } else if (app.status == AppointmentStatus.scheduled) {
        _therapistsMetrics[therapistId]!['upcomingAppointments'] =
            _therapistsMetrics[therapistId]!['upcomingAppointments'] + 1;
      }

      // Contar por tipo de tratamiento
      final treatmentType = app.treatmentType;
      if (_therapistsMetrics[therapistId]!['treatmentTypes']
          is Map<String, int>) {
        final treatmentTypes =
            _therapistsMetrics[therapistId]!['treatmentTypes']
                as Map<String, int>;
        treatmentTypes[treatmentType] =
            (treatmentTypes[treatmentType] ?? 0) + 1;
      }

      // Contar por día de la semana
      final dayOfWeek = app.date.weekday;
      if (_therapistsMetrics[therapistId]!['dayOfWeekDistribution']
          is Map<int, int>) {
        final dayDistribution =
            _therapistsMetrics[therapistId]!['dayOfWeekDistribution']
                as Map<int, int>;
        dayDistribution[dayOfWeek] = (dayDistribution[dayOfWeek] ?? 0) + 1;
      }

      // Calcular duración de la cita en minutos
      final startMinutes = app.startTime.hour * 60 + app.startTime.minute;
      final endMinutes = app.endTime.hour * 60 + app.endTime.minute;
      int duration = endMinutes - startMinutes;
      if (duration < 0) duration += 24 * 60; // Ajustar si cruza la medianoche

      // Acumular duración para calcular promedio después
      _therapistsMetrics[therapistId]!['totalDuration'] =
          (_therapistsMetrics[therapistId]!['totalDuration'] ?? 0) + duration;
    }

    // Calcular métricas finales para cada terapeuta
    for (final therapistId in _therapistsMetrics.keys) {
      final metrics = _therapistsMetrics[therapistId]!;

      // Calcular duración promedio de las citas
      metrics['averageDuration'] = metrics['totalAppointments'] > 0
          ? (metrics['totalDuration'] ?? 0) / metrics['totalAppointments']
          : 0.0;

      // Calcular tasa de completitud (excluyendo citas programadas a futuro)
      final relevantAppointments =
          metrics['completedAppointments'] + metrics['cancelledAppointments'];
      metrics['completionRate'] = relevantAppointments > 0
          ? (metrics['completedAppointments'] / relevantAppointments) * 100
          : 0.0;

      // Calcular tasa de cancelación
      metrics['cancellationRate'] = relevantAppointments > 0
          ? (metrics['cancelledAppointments'] / relevantAppointments) * 100
          : 0.0;
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  // Obtener lista de tratamientos únicos
  List<String> _getUniqueTreatmentTypes() {
    final Set<String> treatmentTypes = {};
    for (final app in _allAppointments) {
      treatmentTypes.add(app.treatmentType);
    }
    return treatmentTypes.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          text: 'Análisis de Terapeutas',
          mobileFontSize: 18,
          tabletFontSize: 20,
          desktopFontSize: 22,
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          // Botón para exportar a PDF/Excel (funcionalidad futura)
          ResponsiveVisibility(
            visibleOnMobile: false,
            child: IconButton(
              icon: Icon(Icons.file_download),
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
            icon: Icon(Icons.refresh),
            tooltip: 'Recargar datos',
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveBreakpoints.isMobile(context) ? 8 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Período:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveBreakpoints.isMobile(context) ? 14 : 16,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  dropdownColor: AppTheme.primaryColor,
                  style: TextStyle(color: Colors.white),
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
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
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de filtros
                _buildFilterBar(),
                // Contenido principal
                Expanded(
                  child: _buildTherapistsList(),
                ),
              ],
            ),
    );
  }

  // Barra de filtros
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
            _buildTherapistFilter(),
            SizedBox(height: 8),
            _buildTreatmentTypeFilter(),
          ],
        ),
        tabletLayout: Row(
          children: [
            Expanded(child: _buildTherapistFilter()),
            SizedBox(width: 8),
            Expanded(child: _buildTreatmentTypeFilter()),
          ],
        ),
      ),
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
        isExpanded: true,
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

  // Filtro de tipos de tratamiento
  Widget _buildTreatmentTypeFilter() {
    final treatmentTypes = _getUniqueTreatmentTypes();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: _selectedTreatmentType,
        hint: Text('Todos los tratamientos'),
        underline: Container(),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down),
        onChanged: (String? newValue) {
          setState(() {
            _selectedTreatmentType = newValue;
            _processTherapistMetrics();
          });
        },
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('Todos los tratamientos'),
          ),
          ...treatmentTypes.map((type) {
            return DropdownMenuItem<String?>(
              value: type,
              child: Text(type),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Lista de terapeutas con sus métricas
  Widget _buildTherapistsList() {
    if (_therapistsMetrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No hay datos de terapeutas para mostrar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar terapeutas por número de citas (descendente)
    final sortedTherapists = _therapistsMetrics.values.toList()
      ..sort(
          (a, b) => b['totalAppointments'].compareTo(a['totalAppointments']));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del período
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 12),
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

          // Tarjetas para cada terapeuta
          ...sortedTherapists
              .map((metrics) => _buildTherapistCard(metrics))
              .toList(),
        ],
      ),
    );
  }

  // Tarjeta de métricas para un terapeuta
  Widget _buildTherapistCard(Map<String, dynamic> metrics) {
    final therapist = metrics['therapist'] as UserModel;
    final totalAppointments = metrics['totalAppointments'] as int;
    final completedAppointments = metrics['completedAppointments'] as int;
    final cancelledAppointments = metrics['cancelledAppointments'] as int;
    final upcomingAppointments = metrics['upcomingAppointments'] as int;
    final unpaidAppointments = metrics['unpaidAppointments'] as int;
    final completionRate = metrics['completionRate'] as double;
    final cancellationRate = metrics['cancellationRate'] as double;
    final averageDuration = metrics['averageDuration'] as double;

    // Minutos a horas:minutos
    final avgHours = (averageDuration / 60).floor();
    final avgMinutes = (averageDuration % 60).floor();
    final avgDurationFormatted = '${avgHours}h ${avgMinutes}m';

    // Tratamientos más comunes
    final treatmentTypes = metrics['treatmentTypes'] as Map<String, int>;
    final sortedTreatments = treatmentTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Color para tasas de completitud/cancelación
    final completionColor = completionRate >= 90
        ? Colors.green
        : completionRate >= 70
            ? Colors.amber
            : Colors.red;

    final cancellationColor = cancellationRate <= 10
        ? Colors.green
        : cancellationRate <= 30
            ? Colors.amber
            : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          therapist.fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Total citas: $totalAppointments'),
            SizedBox(height: 2),
            Row(
              children: [
                Text('Completitud: '),
                Text(
                  '${completionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: completionColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: EdgeInsets.all(16),
        children: [
          Divider(),

          // Estadísticas de citas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricRow(Icons.check_circle, Colors.green,
                        'Completadas', '$completedAppointments'),
                    SizedBox(height: 8),
                    _buildMetricRow(Icons.cancel, Colors.red, 'Canceladas',
                        '$cancelledAppointments'),
                    SizedBox(height: 8),
                    _buildMetricRow(Icons.pending_actions, Colors.blue,
                        'Programadas', '$upcomingAppointments'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricRow(Icons.payment, Colors.orange, 'Pend. Pago',
                        '$unpaidAppointments'),
                    SizedBox(height: 8),
                    _buildMetricRow(Icons.timer, AppTheme.primaryColor,
                        'Duración prom.', avgDurationFormatted),
                    SizedBox(height: 8),
                    _buildMetricRow(
                        Icons.trending_down,
                        cancellationColor,
                        'Tasa cancelación',
                        '${cancellationRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Tratamientos más frecuentes
          if (sortedTreatments.isNotEmpty) ...[
            Text(
              'Tratamientos más frecuentes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            ...sortedTreatments.take(3).map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.spa, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value} ${entry.value == 1 ? 'cita' : 'citas'}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          SizedBox(height: 16),

          // Días de mayor actividad
          _buildDayOfWeekDistribution(metrics),

          SizedBox(height: 16),

          // Botón para ver más detalles
          Center(
            child: OutlinedButton.icon(
              icon: Icon(Icons.visibility),
              label: Text('Ver historial completo'),
              onPressed: () {
                // Aquí podrías navegar a una vista detallada del terapeuta
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Función en desarrollo')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fila para una métrica individual
  Widget _buildMetricRow(
      IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Gráfico de distribución por día de la semana
  Widget _buildDayOfWeekDistribution(Map<String, dynamic> metrics) {
    final dayDistribution = metrics['dayOfWeekDistribution'] as Map<int, int>;

    if (dayDistribution.isEmpty) {
      return Container();
    }

    // Preparar datos para el gráfico
    final List<int> days = [1, 2, 3, 4, 5, 6, 7];
    final maxAppointments = dayDistribution.values.isEmpty
        ? 0
        : dayDistribution.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución por día de la semana',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAppointments * 1.2,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          _getDayName(value.toInt()).substring(0,
                              ResponsiveBreakpoints.isMobile(context) ? 1 : 3),
                          style: TextStyle(
                            fontSize: ResponsiveBreakpoints.isMobile(context)
                                ? 10
                                : 12,
                          ),
                        ),
                      );
                    },
                    reservedSize:
                        ResponsiveBreakpoints.isMobile(context) ? 12 : 16,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: ResponsiveBreakpoints.isMobile(context)
                                ? 10
                                : 12,
                          ),
                        ),
                      );
                    },
                    reservedSize:
                        ResponsiveBreakpoints.isMobile(context) ? 24 : 28,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: days.map((day) {
                return BarChartGroupData(
                  x: day,
                  barRods: [
                    BarChartRodData(
                      toY: (dayDistribution[day] ?? 0).toDouble(),
                      color: AppTheme.primaryColor,
                      width: ResponsiveBreakpoints.isMobile(context) ? 12 : 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
