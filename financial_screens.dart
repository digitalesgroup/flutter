//lib/screens/financial_screens.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart'; // Nuevo import
import '../services/database_service.dart';
import '../widgets/common_widgets.dart';
import '../routes.dart'; // Para navegación

// Define Transaction Range Enum
enum TransactionRange { today, week, month }

// **************************************************************************
//                                  PARTE 1
//                     FinancialDashboardScreen y su State
// **************************************************************************

// Financial Dashboard Screen
class FinancialDashboardScreen extends StatefulWidget {
  final int initialTab;

  const FinancialDashboardScreen({this.initialTab = 0});

  @override
  _FinancialDashboardScreenState createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Daily summary
  Map<String, dynamic> _dailySummary = {
    'totalPayments': 0.0,
    'totalDebts': 0.0,
    'netIncome': 0.0,
    'transactionCount': 0,
  };
  DateTime _selectedDate = DateTime.now();

  // Monthly summary
  Map<String, dynamic> _monthlySummary = {
    'totalPayments': 0.0,
    'totalDebts': 0.0,
    'netIncome': 0.0,
    'transactionCount': 0,
    'dailyRevenue': <int, double>{},
  };
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Transactions list & search
  List<TransactionModel> _transactions = [];
  List<UserModel> _clients = [];
  TransactionRange _selectedRange = TransactionRange.today;
  UserModel? _selectedSearchClient;
  final TextEditingController _clientSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex: widget.initialTab); // Cambiado a 4 pestañas
    _loadFinancialData();
    _loadTransactionsForSelectedRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dailySummary =
          await dbService.getDailyFinancialSummary(_selectedDate);
      final monthlySummary = await dbService.getMonthlyFinancialSummary(
          _selectedYear, _selectedMonth);
      final clients = await dbService.getClients();
      setState(() {
        _dailySummary = dailySummary;
        _monthlySummary = monthlySummary;
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading financial data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar datos financieros: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _loadDailyData(DateTime date) async {
    setState(() {
      _isLoading = true;
      _selectedDate = date;
      _selectedRange = TransactionRange.today;
    });
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dailySummary = await dbService.getDailyFinancialSummary(date);
      final transactions = await dbService.getTransactionsByDate(date);
      setState(() {
        _dailySummary = dailySummary;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading daily data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar datos diarios: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _loadMonthlyData(int year, int month) async {
    setState(() {
      _isLoading = true;
      _selectedYear = year;
      _selectedMonth = month;
    });
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final monthlySummary =
          await dbService.getMonthlyFinancialSummary(year, month);
      setState(() {
        _monthlySummary = monthlySummary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading monthly data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar datos mensuales: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _loadTransactionsForSelectedRange() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      List<TransactionModel> transactions = [];
      switch (_selectedRange) {
        case TransactionRange.today:
          transactions = await dbService.getTransactionsByDate(_selectedDate);
          break;
        case TransactionRange.week:
          transactions = await dbService.getTransactionsForWeek();
          break;
        case TransactionRange.month:
          transactions = await dbService.getTransactionsForMonth();
          break;
      }
      if (_selectedSearchClient != null) {
        transactions = transactions
            .where((transaction) =>
                transaction.clientId == _selectedSearchClient!.id)
            .toList();
      }
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions for range: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar transacciones: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  void _setTransactionRange(TransactionRange range) {
    setState(() {
      _selectedRange = range;
      _selectedSearchClient = null;
      _clientSearchController.clear();
    });
    _loadTransactionsForSelectedRange();
  }

  String _getTransactionTitleText() {
    switch (_selectedRange) {
      case TransactionRange.today:
        return 'Transacciones: ${DateFormat('d MMM, yyyy', 'es').format(_selectedDate)}';
      case TransactionRange.week:
        return 'Transacciones de la Semana';
      case TransactionRange.month:
        final monthName = DateFormat('MMMM', 'es')
            .format(DateTime(_selectedYear, _selectedMonth));
        return 'Transacciones de ${monthName.capitalize()}';
      default:
        return 'Transacciones';
    }
  }

  Widget _buildDailyInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Resumen Diario',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      _loadDailyData(pickedDate);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, d MMMM, yyyy', 'es').format(_selectedDate),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(Icons.arrow_upward, Colors.green, 'Ingresos',
                    '\$${_dailySummary['totalPayments'].toStringAsFixed(2)}'),
                _buildInfoItem(
                    Icons.arrow_downward,
                    Colors.red,
                    'Deudas Pendientes por Cobrar',
                    '\$${_dailySummary['totalDebts'].toStringAsFixed(2)}'),
                _buildInfoItem(Icons.account_balance, Colors.blue, 'Neto',
                    '\$${_dailySummary['netIncome'].toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 32),
            Text('Transacciones: ${_dailySummary['transactionCount']}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyInfoCard() {
    final monthName = DateFormat('MMMM', 'es')
        .format(DateTime(_selectedYear, _selectedMonth));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Resumen Mensual',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (index) {
                    final monthName = DateFormat('MMMM', 'es')
                        .format(DateTime(2020, index + 1));
                    return DropdownMenuItem(
                        value: index + 1, child: Text(monthName));
                  }),
                  onChanged: (month) {
                    if (month != null) {
                      _loadMonthlyData(_selectedYear, month);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${monthName.capitalize()} $_selectedYear',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(Icons.arrow_upward, Colors.green, 'Ingresos',
                    '\$${_monthlySummary['totalPayments'].toStringAsFixed(2)}'),
                _buildInfoItem(
                    Icons.arrow_downward,
                    Colors.red,
                    'Deudas Pendientes por Cobrar',
                    '\$${_monthlySummary['totalDebts'].toStringAsFixed(2)}'),
                _buildInfoItem(Icons.account_balance, Colors.blue, 'Neto',
                    '\$${_monthlySummary['netIncome'].toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Ingresos Diarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: _buildMonthlyBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final List<BarChartGroupData> barGroups = [];
    final dailyRevenue =
        (_monthlySummary['dailyRevenue'] as Map<dynamic, dynamic>?) ?? {};
    double maxRevenue = 0;
    for (var i = 1; i <= daysInMonth; i++) {
      final revenue = dailyRevenue[i] ?? 0.0;
      if (revenue > maxRevenue) {
        maxRevenue = revenue;
      }
    }

    for (var i = 1; i <= daysInMonth; i++) {
      final revenue = dailyRevenue[i] ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
                toY: revenue,
                color: Colors.blue,
                width: 8,
                borderRadius: BorderRadius.circular(4)),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue > 0 ? (maxRevenue * 1.2) : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Día ${group.x}\n',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                      text: '\$${rod.toY.toStringAsFixed(2)}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 || value == 1 || value == daysInMonth) {
                  return Text('${value.toInt()}',
                      style:
                          const TextStyle(color: Colors.black, fontSize: 10));
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
                if (value == 0) {
                  return const Text('\$0');
                }
                if (maxRevenue > 0) {
                  if (value == maxRevenue * 0.5 || value == maxRevenue) {
                    return Text('\$${value.toInt()}',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 10));
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
            horizontalInterval: maxRevenue > 0 ? (maxRevenue / 5) : 20),
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon, Color color, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  String _getUserName(String userId) {
    final client = _clients.firstWhere(
      (c) => c.id == userId,
      orElse: () => UserModel(
        id: '',
        name: 'Cliente',
        lastName: 'Desconocido',
        role: UserRole.client,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return client.fullName;
  }

  Widget _buildTransactionsList() {
    List<TransactionModel> filteredTransactions = _transactions;
    if (_selectedSearchClient != null) {
      filteredTransactions = _transactions
          .where((transaction) =>
              transaction.clientId == _selectedSearchClient!.id)
          .toList();
    }

    return filteredTransactions.isEmpty
        ? const Center(
            child: Text('No hay transacciones para este rango de fecha'))
        : ListView.builder(
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.type == TransactionType.payment
                      ? Colors.green
                      : Colors.red,
                  child: Icon(
                    transaction.type == TransactionType.payment
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  _getUserName(transaction.clientId),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${transaction.type == TransactionType.payment ? 'Pago' : 'Pendiente de cobro'} - ${_getPaymentMethodName(transaction.method)}',
                    ),
                    Text(
                      DateFormat('d MMM, yyyy', 'es').format(transaction.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.payment
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                onTap: () => _showTransactionDetails(transaction),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Transacciones'),
            Tab(text: 'Nueva Transacción'),
            Tab(text: 'Citas por Cobrar'), // Nueva pestaña
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Resumen
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadFinancialData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailyInfoCard(),
                        const SizedBox(height: 16),
                        _buildMonthlyInfoCard(),
                      ],
                    ),
                  ),
                ),

          // Pestaña 2: Transacciones
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadTransactionsForSelectedRange(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _setTransactionRange(
                                        TransactionRange.today),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _selectedRange ==
                                              TransactionRange.today
                                          ? Colors.blue
                                          : Colors.grey[300],
                                      foregroundColor: _selectedRange ==
                                              TransactionRange.today
                                          ? Colors.white
                                          : Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 12),
                                    ),
                                    child: const Text('Hoy'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _setTransactionRange(
                                        TransactionRange.week),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _selectedRange ==
                                              TransactionRange.week
                                          ? Colors.blue
                                          : Colors.grey[300],
                                      foregroundColor: _selectedRange ==
                                              TransactionRange.week
                                          ? Colors.white
                                          : Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 12),
                                    ),
                                    child: const Text('Semana'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _setTransactionRange(
                                        TransactionRange.month),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _selectedRange ==
                                              TransactionRange.month
                                          ? Colors.blue
                                          : Colors.grey[300],
                                      foregroundColor: _selectedRange ==
                                              TransactionRange.month
                                          ? Colors.white
                                          : Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 12),
                                    ),
                                    child: const Text('Mes'),
                                  ),
                                ],
                              ),
                            ),
                            // Date Selector Icon Button aligned to the right
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  if (_selectedRange ==
                                      TransactionRange.today) {
                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      _loadDailyData(pickedDate);
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TypeAheadFormField<UserModel>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: _clientSearchController,
                            decoration: const InputDecoration(
                              labelText: 'Buscar Cliente',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value!.isEmpty) {
                                setState(() {
                                  _selectedSearchClient = null;
                                });
                                _loadTransactionsForSelectedRange();
                              }
                            },
                          ),
                          suggestionsCallback: (pattern) {
                            final query = pattern.toLowerCase().trim();
                            if (query.isEmpty) {
                              return const Iterable<UserModel>.empty();
                            }
                            return _clients.where((c) =>
                                c.fullName.toLowerCase().contains(query));
                          },
                          itemBuilder: (context, UserModel suggestion) {
                            return ListTile(
                              title: Text(suggestion.fullName),
                            );
                          },
                          onSuggestionSelected: (UserModel suggestion) {
                            setState(() {
                              _selectedSearchClient = suggestion;
                              _clientSearchController.text =
                                  suggestion.fullName;
                            });
                            _loadTransactionsForSelectedRange();
                          },
                          noItemsFoundBuilder: (context) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '¡No se encontraron resultados!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _getTransactionTitleText(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildTransactionsList(),
                      ),
                    ],
                  ),
                ),

          // Pestaña 3: Nueva Transacción
          NewTransactionForm(
            clients: _clients,
            onTransactionAdded: () {
              _loadDailyData(_selectedDate);
              _loadMonthlyData(_selectedYear, _selectedMonth);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Transacción registrada exitosamente'),
                  backgroundColor: Colors.green));
              _tabController.animateTo(1);
            },
          ),

          // Pestaña 4: Citas por Cobrar (Nueva)
          PendingPaymentAppointmentsTab(
            onTransactionCreated: () {
              // Recargar datos cuando se cree una transacción desde la pestaña
              _loadDailyData(_selectedDate);
              _loadMonthlyData(_selectedYear, _selectedMonth);
              _loadTransactionsForSelectedRange();
            },
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      default:
        return 'Desconocido';
    }
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Transacción'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  title: const Text('Cliente'),
                  subtitle: Text(_getUserName(transaction.clientId))),
              ListTile(
                title: const Text('Tipo'),
                subtitle: Text(transaction.type == TransactionType.payment
                    ? 'Pago'
                    : 'Deuda'),
              ),
              ListTile(
                  title: const Text('Monto'),
                  subtitle: Text('\$${transaction.amount.toStringAsFixed(2)}')),
              ListTile(
                  title: const Text('Método de Pago'),
                  subtitle: Text(_getPaymentMethodName(transaction.method))),
              ListTile(
                title: const Text('Estado'),
                subtitle: Text(transaction.status == TransactionStatus.completed
                    ? 'Completado'
                    : 'Pendiente'),
              ),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('d MMM, yyyy HH:mm', 'es')
                    .format(transaction.date)),
              ),
              if (transaction.notes?.isNotEmpty ?? false)
                ListTile(
                    title: const Text('Notas'),
                    subtitle: Text(transaction.notes!)),
              if (transaction.voucherNumber?.isNotEmpty ?? false)
                ListTile(
                  title: const Text('Número de Comprobante'),
                  subtitle: Text(transaction.voucherNumber!),
                ),
              // Mostrar citas asociadas (si las hay)
              if (transaction.hasAppointments) ...[
                const Divider(),
                const ListTile(
                  title: Text('Citas Asociadas',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                FutureBuilder<List<AppointmentModel>>(
                  future: Provider.of<DatabaseService>(context, listen: false)
                      .getAppointmentsForTransaction(transaction.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('  No hay citas asociadas');
                    }
                    return Column(
                      children: snapshot.data!.map((appointment) {
                        return ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(appointment.treatmentType),
                          subtitle: Text(
                              '${DateFormat('d MMM, yyyy', 'es').format(appointment.date)} - ${appointment.startTime.format(context)}'),
                          dense: true,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (transaction.type == TransactionType.debt)
            TextButton(
              onPressed: () async => await _markTransactionAsPaid(transaction),
              child: const Text('Marcar como pagada'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _markTransactionAsPaid(TransactionModel transaction) async {
    PaymentMethod? selectedPaymentMethod;
    String? voucherNumber;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        PaymentMethod dialogPaymentMethod = PaymentMethod.cash;
        final voucherController = TextEditingController();

        return AlertDialog(
          title: const Text('Marcar como Pagada'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccione el método de pago:'),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Efectivo'),
                      value: PaymentMethod.cash,
                      groupValue: dialogPaymentMethod,
                      onChanged: (value) =>
                          dialogSetState(() => dialogPaymentMethod = value!),
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Tarjeta'),
                      value: PaymentMethod.card,
                      groupValue: dialogPaymentMethod,
                      onChanged: (value) =>
                          dialogSetState(() => dialogPaymentMethod = value!),
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Transferencia'),
                      value: PaymentMethod.transfer,
                      groupValue: dialogPaymentMethod,
                      onChanged: (value) =>
                          dialogSetState(() => dialogPaymentMethod = value!),
                    ),
                    Visibility(
                      visible: dialogPaymentMethod == PaymentMethod.card ||
                          dialogPaymentMethod == PaymentMethod.transfer,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: voucherController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Comprobante (Opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Marcar como Pagada'),
              onPressed: () {
                selectedPaymentMethod = dialogPaymentMethod;
                voucherNumber = voucherController.text.trim();
                Navigator.of(dialogContext).pop();
                _updateTransactionToPaid(
                    transaction, selectedPaymentMethod!, voucherNumber);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTransactionToPaid(TransactionModel transaction,
      PaymentMethod paymentMethod, String? voucherNumber) async {
    // Actualiza la transacción a pago completado, incluyendo método de pago y número de comprobante
    final updatedTransaction = transaction.copyWith(
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      method: paymentMethod, // Usar el método de pago seleccionado
      voucherNumber:
          voucherNumber, // Guardar el número de comprobante (opcional)
      updatedAt: DateTime.now(),
      notes:
          '${transaction.notes ?? ''}\nPagado el ${DateFormat('d MMM, yyyy', 'es').format(DateTime.now())}', // Add note
    );

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.updateTransaction(updatedTransaction);

      // Cierra el diálogo de detalles (si está abierto) - Ya no es necesario aquí, el diálogo de pago se cierra antes

      // Vuelve a cargar la data diaria y mensual para refrescar
      await _loadDailyData(_selectedDate);
      await _loadMonthlyData(_selectedYear, _selectedMonth);
      _loadTransactionsForSelectedRange(); // And refresh transactions.  Important!

      // Opcional: Muestra un snackbar de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡La transacción se ha marcado como pagada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar como pagada: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// **************************************************************************
//                                  FIN PARTE 1
// **************************************************************************

// **************************************************************************
//                                  PARTE 2
//                       NewTransactionForm y su State
// **************************************************************************

class NewTransactionForm extends StatefulWidget {
  final List<UserModel> clients;
  final VoidCallback onTransactionAdded;

  const NewTransactionForm(
      {required this.clients, required this.onTransactionAdded});

  @override
  _NewTransactionFormState createState() => _NewTransactionFormState();
}

class _NewTransactionFormState extends State<NewTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  UserModel? _selectedClient;
  TransactionType _transactionType = TransactionType.payment;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _voucherController = TextEditingController();
  final _clientSearchController = TextEditingController();
  DateTime _transactionDate = DateTime.now();
  bool _isSubmitting = false;

  // Nuevas propiedades para citas
  List<AppointmentModel> _unpaidAppointments = [];
  List<String> _selectedAppointmentIds = [];
  bool _loadingAppointments = false;

  @override
  void initState() {
    super.initState();
    // Verificar si hay parámetros de cita preseleccionada
    _loadUnpaidAppointments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _voucherController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  // Nuevo método para cargar citas sin pago
  Future<void> _loadUnpaidAppointments() async {
    if (_selectedClient == null) return;

    setState(() => _loadingAppointments = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final unpaidAppointments =
          await dbService.getUnpaidCompletedAppointments();

      // Filtrar por cliente seleccionado
      setState(() {
        _unpaidAppointments = unpaidAppointments
            .where((a) => a.clientId == _selectedClient!.id)
            .toList();
        _loadingAppointments = false;
      });
    } catch (e) {
      print('Error loading unpaid appointments: $e');
      setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _transactionDate) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedClient == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Por favor seleccione un cliente'),
            backgroundColor: Colors.red));
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final transactionModel = TransactionModel(
          id: '',
          clientId: _selectedClient!.id,
          amount: double.parse(_amountController.text),
          type: _transactionType,
          method: _transactionType == TransactionType.payment
              ? _paymentMethod
              : PaymentMethod.unknown,
          status: _transactionType == TransactionType.payment
              ? TransactionStatus.completed
              : TransactionStatus.pending,
          date: _transactionDate,
          notes: _notesController.text.trim(),
          voucherNumber: _voucherController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          description: _transactionType == TransactionType.payment
              ? 'Pago de cliente'
              : 'Deuda de cliente',
          appointmentIds: _selectedAppointmentIds.isNotEmpty
              ? _selectedAppointmentIds
              : null,
        );

        // Si hay citas seleccionadas, usar el nuevo método para vincularlas
        if (_selectedAppointmentIds.isNotEmpty) {
          await dbService.addTransactionWithAppointments(
              transactionModel, _selectedAppointmentIds);
        } else {
          // Si no hay citas, usar el método existente
          await dbService.addTransaction(transactionModel);
        }

        _resetForm();
        widget.onTransactionAdded();
      } catch (e) {
        print('Error adding transaction: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al registrar transacción: ${e.toString()}'),
            backgroundColor: Colors.red));
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedClient = null;
      _transactionType = TransactionType.payment;
      _paymentMethod = PaymentMethod.cash;
      _amountController.clear();
      _notesController.clear();
      _voucherController.clear();
      _transactionDate = DateTime.now();
      _selectedAppointmentIds = [];
      _unpaidAppointments = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Nueva Transacción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TypeAheadFormField<UserModel>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _clientSearchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar cliente',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              suggestionsCallback: (pattern) {
                final query = pattern.toLowerCase().trim();
                if (query.isEmpty) {
                  return const Iterable<UserModel>.empty();
                }
                return widget.clients
                    .where((c) => c.fullName.toLowerCase().contains(query));
              },
              itemBuilder: (context, UserModel suggestion) {
                return ListTile(
                  title: Text(suggestion.fullName),
                );
              },
              onSuggestionSelected: (UserModel suggestion) {
                setState(() {
                  _selectedClient = suggestion;
                  _clientSearchController.text = suggestion.fullName;
                  _selectedAppointmentIds =
                      []; // Limpiar selecciones anteriores
                });
                // Cargar citas pendientes para este cliente
                _loadUnpaidAppointments();
              },
              noItemsFoundBuilder: (context) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '¡No se encontraron resultados!',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
              validator: (value) {
                if (_selectedClient == null) {
                  return 'Por favor seleccione un cliente';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: '0.00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Por favor ingrese el monto';
                try {
                  final amount = double.parse(value);
                  if (amount <= 0) return 'El monto debe ser mayor que cero';
                } catch (e) {
                  return 'Por favor ingrese un monto válido';
                }
                return null;
              },
            ),

            // Sección de citas pendientes (nueva)
            if (_transactionType == TransactionType.payment &&
                !_loadingAppointments &&
                _unpaidAppointments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Citas Pendientes de Pago',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _unpaidAppointments.map((appointment) {
                        bool isSelected =
                            _selectedAppointmentIds.contains(appointment.id);
                        return CheckboxListTile(
                          title: Text(appointment.treatmentType),
                          subtitle: Text(
                              '${DateFormat('d MMM, yyyy', 'es').format(appointment.date)} - ${appointment.startTime.format(context)}'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedAppointmentIds.add(appointment.id);
                              } else {
                                _selectedAppointmentIds.remove(appointment.id);
                              }
                            });
                          },
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
            const Text('Tipo de Transacción',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: const Text('Pago'),
                    value: TransactionType.payment,
                    groupValue: _transactionType,
                    onChanged: (value) =>
                        setState(() => _transactionType = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: const Text('Pendiente de cobro'),
                    value: TransactionType.debt,
                    groupValue: _transactionType,
                    onChanged: (value) =>
                        setState(() => _transactionType = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Visibility(
              visible: _transactionType == TransactionType.payment,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Método de Pago',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          title: const Text('Efectivo'),
                          value: PaymentMethod.cash,
                          groupValue: _paymentMethod,
                          onChanged: (value) =>
                              setState(() => _paymentMethod = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          title: const Text('Tarjeta'),
                          value: PaymentMethod.card,
                          groupValue: _paymentMethod,
                          onChanged: (value) =>
                              setState(() => _paymentMethod = value!),
                        ),
                      ),
                    ],
                  ),
                  RadioListTile<PaymentMethod>(
                    title: const Text('Transferencia'),
                    value: PaymentMethod.transfer,
                    groupValue: _paymentMethod,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value!),
                  ),
                  const SizedBox(height: 16),
                  Visibility(
                    visible: _paymentMethod == PaymentMethod.card ||
                        _paymentMethod == PaymentMethod.transfer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Número de Comprobante (Opcional)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _voucherController,
                          decoration: const InputDecoration(
                              labelText: 'Número de Comprobante',
                              prefixIcon: Icon(Icons.receipt),
                              border: OutlineInputBorder(),
                              hintText: 'Opcional'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder()),
                  controller: TextEditingController(
                      text: DateFormat('EEEE, d MMMM, yyyy', 'es')
                          .format(_transactionDate)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                  labelText: 'Notas',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Registrar Transacción'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// **************************************************************************
//                                  FIN PARTE 2
// **************************************************************************

// **************************************************************************
//                                  PARTE 3
//                      ClientPaymentsTab y su State
// **************************************************************************

class ClientPaymentsTab extends StatefulWidget {
  final String clientId;

  const ClientPaymentsTab({required this.clientId});

  @override
  _ClientPaymentsTabState createState() => _ClientPaymentsTabState();
}

class _ClientPaymentsTabState extends State<ClientPaymentsTab> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final transactions =
          await dbService.getClientTransactions(widget.clientId);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar transacciones: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
            ? const Center(
                child: Text('No hay transacciones para este cliente'))
            : RefreshIndicator(
                onRefresh: _loadTransactions,
                child: ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            transaction.type == TransactionType.payment
                                ? Colors.green
                                : Colors.red,
                        child: Icon(
                          transaction.type == TransactionType.payment
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(transaction.type == TransactionType.payment
                          ? 'Pago'
                          : 'Deuda'),
                      subtitle: Text(
                          '${DateFormat('d MMM, yyyy', 'es').format(transaction.date)} - ${_getPaymentMethodName(transaction.method)}'),
                      trailing: Text(
                        '\$${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction.type == TransactionType.payment
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      onTap: () => _showTransactionDetails(transaction),
                    );
                  },
                ),
              );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      default:
        return 'Desconocido';
    }
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Transacción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
                title: const Text('Tipo'),
                subtitle: Text(transaction.type == TransactionType.payment
                    ? 'Pago'
                    : 'Deuda')),
            ListTile(
                title: const Text('Monto'),
                subtitle: Text('\$${transaction.amount.toStringAsFixed(2)}')),
            ListTile(
                title: const Text('Método de Pago'),
                subtitle: Text(_getPaymentMethodName(transaction.method))),
            ListTile(
              title: const Text('Estado'),
              subtitle: Text(transaction.status == TransactionStatus.completed
                  ? 'Completado'
                  : 'Pendiente'),
            ),
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('d MMM, yyyy HH:mm', 'es')
                  .format(transaction.date)),
            ),
            if (transaction.notes?.isNotEmpty ?? false)
              ListTile(
                  title: const Text('Notas'),
                  subtitle: Text(transaction.notes!)),
            if (transaction.voucherNumber?.isNotEmpty ?? false)
              ListTile(
                title: const Text('Número de Comprobante'),
                subtitle: Text(transaction.voucherNumber!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// **************************************************************************
//                                  FIN PARTE 3
// **************************************************************************

// **************************************************************************
//                                 PARTE 4
//                      Nueva pestaña de citas por cobrar
// **************************************************************************

class PendingPaymentAppointmentsTab extends StatefulWidget {
  final VoidCallback? onTransactionCreated;

  const PendingPaymentAppointmentsTab({Key? key, this.onTransactionCreated})
      : super(key: key);

  @override
  _PendingPaymentAppointmentsTabState createState() =>
      _PendingPaymentAppointmentsTabState();
}

class _PendingPaymentAppointmentsTabState
    extends State<PendingPaymentAppointmentsTab> {
  bool _isLoading = true;
  List<AppointmentModel> _unpaidAppointments = [];
  List<UserModel> _clients = [];
  List<UserModel> _employees = [];
  Set<String> _selectedAppointments = {}; // Guarda IDs de citas seleccionadas

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Cargar citas sin pago
      final unpaidAppointments =
          await dbService.getUnpaidCompletedAppointments();

      // Cargar clientes y empleados para mostrar nombres
      final clients = await dbService.getClients();
      final employees = await dbService.getEmployees();

      setState(() {
        _unpaidAppointments = unpaidAppointments;
        _clients = clients;
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading unpaid appointments: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error al cargar citas pendientes de pago: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getClientName(String clientId) {
    final client = _clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => UserModel(
        id: '',
        name: 'Cliente',
        lastName: 'Desconocido',
        role: UserRole.client,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return client.fullName;
  }

  String _getEmployeeName(String employeeId) {
    final employee = _employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => UserModel(
        id: '',
        name: 'Empleado',
        lastName: 'Desconocido',
        role: UserRole.therapist,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return employee.fullName;
  }

  double _getTotalAmount() {
    // En una implementación real, podrías tener una tabla de precios
    // Por ahora usaremos un precio fijo de ejemplo
    return _selectedAppointments.length * 500.0; // 500 por cita
  }

  void _createTransaction() async {
    if (_selectedAppointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Seleccione al menos una cita para crear la transacción'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tomar el primer cliente como referencia (todas las citas seleccionadas deben ser del mismo cliente)
    final firstAppointment = _unpaidAppointments
        .firstWhere((a) => _selectedAppointments.contains(a.id));
    final clientId = firstAppointment.clientId;

    // Verificar que todas las citas seleccionadas sean del mismo cliente
    bool sameClient = _selectedAppointments.every((appointmentId) {
      final appointment =
          _unpaidAppointments.firstWhere((a) => a.id == appointmentId);
      return appointment.clientId == clientId;
    });

    if (!sameClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Todas las citas seleccionadas deben ser del mismo cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo para completar la transacción
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PaymentDialog(
          clientId: clientId,
          clientName: _getClientName(clientId),
          appointmentIds: _selectedAppointments.toList(),
          totalAmount: _getTotalAmount(),
          onTransactionCreated: () {
            // Recargar datos después de crear la transacción
            _loadData();
            // Informar a la pantalla padre que se creó una transacción
            if (widget.onTransactionCreated != null) {
              widget.onTransactionCreated!();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _unpaidAppointments.isEmpty
            ? const Center(child: Text('No hay citas pendientes de pago'))
            : Column(
                children: [
                  // Controles superiores (botones)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Citas Pendientes de Pago: ${_unpaidAppointments.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectedAppointments.isEmpty
                              ? null
                              : _createTransaction,
                          icon: const Icon(Icons.payment),
                          label: const Text('Crear Pago'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de citas
                  Expanded(
                    child: ListView.builder(
                      itemCount: _unpaidAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _unpaidAppointments[index];
                        final isSelected =
                            _selectedAppointments.contains(appointment.id);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedAppointments.add(appointment.id);
                                } else {
                                  _selectedAppointments.remove(appointment.id);
                                }
                              });
                            },
                            title: Text(
                              '${appointment.treatmentType} - ${_getClientName(appointment.clientId)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Fecha: ${DateFormat('d/M/yyyy').format(appointment.date)}'),
                                Text(
                                    'Hora: ${appointment.startTime.format(context)}'),
                                Text(
                                    'Terapeuta: ${_getEmployeeName(appointment.employeeId)}'),
                              ],
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(
                                Icons.attach_money,
                                color: Colors.white,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),
                  // Barra inferior con total seleccionado
                  if (_selectedAppointments.isNotEmpty)
                    Container(
                      color: Colors.green.shade100,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Citas seleccionadas: ${_selectedAppointments.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total: \$${_getTotalAmount().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
  }
}

class PaymentDialog extends StatefulWidget {
  final String clientId;
  final String clientName;
  final List<String> appointmentIds;
  final double totalAmount;
  final VoidCallback onTransactionCreated;

  const PaymentDialog({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.appointmentIds,
    required this.totalAmount,
    required this.onTransactionCreated,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _voucherController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toString();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitTransaction() async {
    // Validar monto
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final transaction = TransactionModel(
        id: '', // Se generará en Firestore
        clientId: widget.clientId,
        appointmentIds: widget.appointmentIds,
        amount: double.parse(_amountController.text),
        type: TransactionType.payment,
        method: _paymentMethod,
        status: TransactionStatus.completed,
        date: DateTime.now(),
        notes: _notesController.text.trim(),
        voucherNumber: _voucherController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description:
            'Pago por servicios - ${widget.appointmentIds.length} citas',
      );

      // Crear transacción y vincular con citas
      await dbService.addTransactionWithAppointments(
          transaction, widget.appointmentIds);

      // Cerrar diálogo y notificar
      Navigator.of(context).pop();
      widget.onTransactionCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transacción creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear transacción: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${widget.clientName}'),
            Text('Citas a cobrar: ${widget.appointmentIds.length}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto Total',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('Método de Pago',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<PaymentMethod>(
              title: const Text('Efectivo'),
              value: PaymentMethod.cash,
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            RadioListTile<PaymentMethod>(
              title: const Text('Tarjeta'),
              value: PaymentMethod.card,
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            RadioListTile<PaymentMethod>(
              title: const Text('Transferencia'),
              value: PaymentMethod.transfer,
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            if (_paymentMethod != PaymentMethod.cash) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _voucherController,
                decoration: const InputDecoration(
                  labelText: 'Número de Comprobante',
                  prefixIcon: Icon(Icons.receipt),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Crear Pago'),
        ),
      ],
    );
  }
}

// **************************************************************************
//                                  FIN PARTE 4
// **************************************************************************
