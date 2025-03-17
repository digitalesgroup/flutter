//lib/screens/admin_screens.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../routes.dart';
import '../app_theme.dart';
import '../widgets/common_widgets.dart';

// Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Dashboard'), Tab(text: 'Empleados')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.signOut();

              // Navigate to login
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          AdminDashboardTab(),

          // Employees Tab
          EmployeesTab(),
        ],
      ),
    );
  }
}

// Admin Dashboard Tab
class AdminDashboardTab extends StatefulWidget {
  @override
  _AdminDashboardTabState createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _isLoading = true;

  // Dashboard data
  int _totalClients = 0;
  int _totalEmployees = 0;
  int _totalAppointmentsToday = 0;
  double _totalRevenueToday = 0;
  double _totalRevenueThisMonth = 0;

  // For charts
  Map<String, double> _treatmentTypeCounts = {};
  Map<String, double> _dailyRevenueForWeek = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Get clients count
      final clients = await dbService.getClients();
      _totalClients = clients.length;

      // Get employees count
      final employees = await dbService.getEmployees();
      _totalEmployees = employees.length;

      // Get today's appointments
      final todayAppointments = await dbService.getAppointmentsByDate(
        DateTime.now(),
      );
      _totalAppointmentsToday = todayAppointments.length;

      // Get today's financial summary
      final todaySummary = await dbService.getDailyFinancialSummary(
        DateTime.now(),
      );
      _totalRevenueToday = todaySummary['totalPayments'] ?? 0.0;

      // Get this month's financial summary
      final now = DateTime.now();
      final monthlySummary = await dbService.getMonthlyFinancialSummary(
        now.year,
        now.month,
      );
      _totalRevenueThisMonth = monthlySummary['totalPayments'] ?? 0.0;

      // Count treatment types
      Map<String, double> treatmentCounts = {};
      for (var appointment in todayAppointments) {
        treatmentCounts[appointment.treatmentType] =
            (treatmentCounts[appointment.treatmentType] ?? 0) + 1;
      }
      _treatmentTypeCounts = treatmentCounts;

      // Get daily revenue for the last 7 days
      Map<String, double> dailyRevenue = {};

      // Get the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final summary = await dbService.getDailyFinancialSummary(date);

        // Format date as day name
        final dayName = DateFormat('E', 'es').format(date);
        dailyRevenue[dayName] = summary['totalPayments'] ?? 0.0;
      }

      _dailyRevenueForWeek = dailyRevenue;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
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
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      _buildStatCard(
                        'Clientes',
                        _totalClients.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Empleados',
                        _totalEmployees.toString(),
                        Icons.person,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Citas Hoy',
                        _totalAppointmentsToday.toString(),
                        Icons.calendar_today,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Ingresos Hoy',
                        '\$${_totalRevenueToday.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Monthly Revenue
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingresos Mensuales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_totalRevenueThisMonth.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Este mes',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Revenue Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingresos de la Semana',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _buildWeeklyRevenueChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Treatment Types Pie Chart
                  if (_treatmentTypeCounts.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipos de Tratamientos (Hoy)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildTreatmentTypesChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyRevenueChart() {
    // If no data, show message
    if (_dailyRevenueForWeek.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    // Convert map to list for chart
    final List<BarChartGroupData> barGroups = [];
    int index = 0;

    // Find max value for scaling
    double maxValue = 0;
    _dailyRevenueForWeek.forEach((day, value) {
      if (value > maxValue) {
        maxValue = value;
      }
    });

    // Create bar groups
    _dailyRevenueForWeek.forEach((day, value) {
      barGroups.add(
        BarChartGroupData(
          x: index++,
          barRods: [
            BarChartRodData(
              toY: value,
              color: AppTheme.primaryColor,
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue > 0 ? (maxValue * 1.2) : 100,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _dailyRevenueForWeek.keys.length) {
                  return Text(
                    _dailyRevenueForWeek.keys.elementAt(value.toInt()),
                    style: const TextStyle(color: Colors.black, fontSize: 10),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (maxValue > 0) {
                  if (value == 0 ||
                      value == maxValue * 0.5 ||
                      value == maxValue) {
                    return Text(
                      '\$${value.toInt()}',
                      style: const TextStyle(color: Colors.black, fontSize: 10),
                    );
                  }
                }
                return const SizedBox();
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? (maxValue / 5) : 20,
        ),
      ),
    );
  }

  Widget _buildTreatmentTypesChart() {
    // If no data, show message
    if (_treatmentTypeCounts.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    // Define colors for pie sections
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    // Convert map to list for chart
    final List<PieChartSectionData> sections = [];
    int index = 0;

    // Calculate total count
    double total = 0;
    _treatmentTypeCounts.forEach((type, count) {
      total += count;
    });

    // Create pie sections
    _treatmentTypeCounts.forEach((type, count) {
      final double percentage = (count / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: count,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(_treatmentTypeCounts.length, (index) {
                final type = _treatmentTypeCounts.keys.elementAt(index);
                final count = _treatmentTypeCounts[type]!.toInt();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: colors[index % colors.length],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(type, style: const TextStyle(fontSize: 12)),
                      ),
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// Employees Tab
class EmployeesTab extends StatefulWidget {
  @override
  _EmployeesTabState createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab> {
  List<UserModel> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Load employees
      final employees = await dbService.getEmployees();

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar empleados: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteEmployeeDialog(UserModel employee) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar a ${employee.fullName}?'),
                const SizedBox(height: 8),
                const Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteEmployee(employee);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee(UserModel employee) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Delete employee (soft delete)
      await dbService.deleteUser(employee.id);

      // Reload employees
      await _loadEmployees();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Empleado ${employee.fullName} eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting employee: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar empleado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.therapist:
        return 'Terapeuta';
      case UserRole.receptionist:
        return 'Recepcionista';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.register);
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEmployees,
              child: _employees.isEmpty
                  ? const Center(
                      child: Text('No hay empleados registrados'),
                    )
                  : ListView.builder(
                      itemCount: _employees.length,
                      itemBuilder: (context, index) {
                        final employee = _employees[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: employee.photoUrl != null
                                  ? NetworkImage(employee.photoUrl!)
                                  : null,
                              child: employee.photoUrl == null
                                  ? Text(employee.name[0])
                                  : null,
                            ),
                            title: Text(employee.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getRoleName(employee.role)),
                                if (employee.phone != null)
                                  Text(employee.phone!),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _showDeleteEmployeeDialog(employee);
                              },
                            ),
                            isThreeLine: employee.phone != null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
