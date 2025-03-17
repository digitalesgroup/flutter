// lib/screens/client_metrics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../app_theme.dart';
import '../widgets/responsive_layout.dart';

class ClientMetricsScreen extends StatefulWidget {
  @override
  _ClientMetricsScreenState createState() => _ClientMetricsScreenState();
}

class _ClientMetricsScreenState extends State<ClientMetricsScreen> {
  // Variables para las métricas
  int _totalClients = 0;
  int _newClientsThisMonth = 0;
  int _uniqueClientsThisMonth = 0;
  int _recurringClientsLastMonth = 0;
  int _recurringClientsLastYear = 0;
  bool _loadingMetrics = true;

  // Datos para el gráfico de tendencias
  List<FlSpot> _clientTrendData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingMetrics = true;
    });

    try {
      await _loadMetrics();
      await _loadClientTrendData();
    } catch (e) {
      print('Error loading metrics data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de métricas: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadMetrics() async {
    if (!mounted) return;

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final metrics = await dbService.getClientMetrics();

      if (!mounted) return;

      setState(() {
        _totalClients = metrics['totalClients'] ?? 0;
        _newClientsThisMonth = metrics['newClientsThisMonth'] ?? 0;
        _uniqueClientsThisMonth = metrics['uniqueClientsThisMonth'] ?? 0;
        _recurringClientsLastMonth = metrics['recurringClientsLastMonth'] ?? 0;
        _recurringClientsLastYear = metrics['recurringClientsLastYear'] ?? 0;
        _loadingMetrics = false;
      });
    } catch (e) {
      print('Error loading metrics: $e');

      if (mounted) {
        setState(() {
          _loadingMetrics = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar métricas: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadClientTrendData() async {
    if (!mounted) return;

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Obtener los últimos 6 meses de datos para la tendencia
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      // Datos de tendencia mensuales
      List<FlSpot> trendData = [];

      for (int i = 0; i < 6; i++) {
        if (!mounted) return; // Verificación adicional en el bucle largo

        final month = DateTime(sixMonthsAgo.year, sixMonthsAgo.month + i, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0);

        // Obtener clientes activos para ese mes
        final clientIds = await dbService.getClientIdsWithActivityInDateRange(
            month, endOfMonth);

        // Añadir punto en el gráfico (x: mes, y: número de clientes)
        trendData.add(FlSpot(i.toDouble(), clientIds.length.toDouble()));
      }

      if (mounted) {
        setState(() {
          _clientTrendData = trendData;
        });
      }
    } catch (e) {
      print('Error loading client trend data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error al cargar datos de tendencia: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);
    final double screenPadding = isMobile ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas de Clientes'),
        // Quitar flecha de retroceso cuando viene del dashboard
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar métricas',
          ),
        ],
      ),
      body: _loadingMetrics
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjetas de resumen expandidas
                  _buildMetricCardsSection(),
                  SizedBox(height: 24),

                  // Distribución de clientes
                  _buildClientDistributionSection(),
                  SizedBox(height: 24),

                  // Tendencia de clientes activos
                  _buildClientTrendSection(),

                  // Podríamos agregar más análisis y visualizaciones aquí
                  SizedBox(height: 24),
                  _buildAdditionalMetricsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCardsSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de Clientes',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        isMobile
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimpleMetricCard('Clientes Registrados',
                            _totalClients.toString(), AppTheme.primaryColor),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildSimpleMetricCard(
                            'Clientes Nuevos',
                            _newClientsThisMonth.toString(),
                            AppTheme.successColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimpleMetricCard(
                            'Clientes Activos',
                            _uniqueClientsThisMonth.toString(),
                            AppTheme.dashboardOrange),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildSimpleMetricCard(
                            'Recurrentes (Mes)',
                            _recurringClientsLastMonth.toString(),
                            AppTheme.dashboardPurple),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildSimpleMetricCard(
                      'Recurrentes (Año)',
                      _recurringClientsLastYear.toString(),
                      AppTheme.dashboardBlue),
                ],
              )
            : Row(
                children: [
                  Expanded(
                      child: _buildSimpleMetricCard('Clientes\nRegistrados',
                          _totalClients.toString(), AppTheme.primaryColor)),
                  SizedBox(width: 12),
                  Expanded(
                      child: _buildSimpleMetricCard(
                          'Clientes\nNuevos',
                          _newClientsThisMonth.toString(),
                          AppTheme.successColor)),
                  SizedBox(width: 12),
                  Expanded(
                      child: _buildSimpleMetricCard(
                          'Clientes\nActivos',
                          _uniqueClientsThisMonth.toString(),
                          AppTheme.dashboardOrange)),
                  SizedBox(width: 12),
                  Expanded(
                      child: _buildSimpleMetricCard(
                          'Recurrentes\n(Mes)',
                          _recurringClientsLastMonth.toString(),
                          AppTheme.dashboardPurple)),
                  SizedBox(width: 12),
                  Expanded(
                      child: _buildSimpleMetricCard(
                          'Recurrentes\n(Año)',
                          _recurringClientsLastYear.toString(),
                          AppTheme.dashboardBlue)),
                ],
              ),
      ],
    );
  }

  Widget _buildClientDistributionSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    // Calcular el total y porcentajes
    final total = _totalClients > 0 ? _totalClients : 1;
    final newPercentage =
        (_newClientsThisMonth / total * 100).toStringAsFixed(1);
    final recurringPercentage =
        (_recurringClientsLastMonth / total * 100).toStringAsFixed(1);
    final otherClients =
        _totalClients - _newClientsThisMonth - _recurringClientsLastMonth;
    final otherPercentage = (otherClients / total * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución de Clientes',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Indicadores de progreso como barras
                Container(
                  height: isMobile ? 150 : 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nuevos clientes
                      _buildProgressBar(
                        'Nuevos',
                        double.parse(newPercentage) / 100,
                        AppTheme.successColor,
                        _newClientsThisMonth,
                        newPercentage,
                      ),

                      // Clientes recurrentes
                      _buildProgressBar(
                        'Recurrentes',
                        double.parse(recurringPercentage) / 100,
                        AppTheme.dashboardPurple,
                        _recurringClientsLastMonth,
                        recurringPercentage,
                      ),

                      // Otros clientes
                      _buildProgressBar(
                        'Otros',
                        double.parse(otherPercentage) / 100,
                        AppTheme.dashboardBlue,
                        otherClients,
                        otherPercentage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientTrendSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencia de Clientes Activos (6 meses)',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              height: isMobile ? 250 : 350,
              child: _clientTrendData.isEmpty
                  ? Center(
                      child: Text(
                        "No hay datos de tendencia disponibles",
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : _buildStableTrendLineChart(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalMetricsSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis Adicional',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasa de Retención',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '${(_recurringClientsLastMonth / (_totalClients > 0 ? _totalClients : 1) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Basado en clientes recurrentes del último mes',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crecimiento Mensual',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_newClientsThisMonth}',
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.trending_up,
                            color: AppTheme.successColor,
                            size: isMobile ? 24 : 28,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Nuevos clientes este mes',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Reutilizamos los widgets del panel original pero mejorados
  Widget _buildSimpleMetricCard(String title, String value, Color color) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final double valueFontSize = isMobile ? 24 : 32;

    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color,
      int count, String percentageText) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final double maxWidth =
        MediaQuery.of(context).size.width * (isMobile ? 0.5 : 0.6);

    return Row(
      children: [
        // Etiqueta
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),

        // Barra de progreso
        Expanded(
          child: Stack(
            children: [
              // Fondo de la barra
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              // Barra de progreso
              Container(
                height: 24,
                width: percentage * maxWidth, // Ancho proporcional y limitado
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),

        // Valor y porcentaje
        SizedBox(width: 10),
        Text(
          "$count ($percentageText%)",
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStableTrendLineChart() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    // Obtener nombres de meses para el eje X
    List<String> monthNames = [];
    if (_clientTrendData.isNotEmpty) {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      for (int i = 0; i < 6; i++) {
        final month = DateTime(sixMonthsAgo.year, sixMonthsAgo.month + i, 1);
        monthNames.add(DateFormat('MMM').format(month));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < monthNames.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      monthNames[index],
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: _getMaxYForChart(),
        lineBarsData: [
          LineChartBarData(
            spots: _clientTrendData,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // Función para determinar el valor máximo del eje Y
  double _getMaxYForChart() {
    if (_clientTrendData.isEmpty) return 10;

    double maxY = 0;
    for (var spot in _clientTrendData) {
      if (spot.y > maxY) maxY = spot.y;
    }

    // Redondear al siguiente múltiplo de 5 para una escala limpia
    return ((maxY ~/ 5) + 1) * 5.0;
  }
}
