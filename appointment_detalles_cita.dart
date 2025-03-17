// lib/screens/appointment_detalles_cita.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../routes.dart';
import '../app_theme.dart';
import '../models/navigation_state.dart';

// Appointment Details Screen
class AppointmentDetailsScreen extends StatefulWidget {
  final String? appointmentId;

  const AppointmentDetailsScreen({this.appointmentId});

  @override
  _AppointmentDetailsScreenState createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  AppointmentModel? _appointment;
  UserModel? _client;
  UserModel? _therapist;
  bool _isLoading = true;
  bool _isProcessing = false;
  late TabController _tabController;

  // Para transacciones vinculadas
  bool _isLoadingTransactions = false;
  List<TransactionModel> _linkedTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointment() async {
    if (widget.appointmentId == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Load appointment
      final appointment = await dbService.getAppointment(widget.appointmentId!);

      // Load client and therapist
      final client = await dbService.getUser(appointment.clientId);
      final therapist = await dbService.getUser(appointment.employeeId);

      setState(() {
        _appointment = appointment;
        _client = client;
        _therapist = therapist;
        _isLoading = false;
      });

      // Cargar transacciones vinculadas
      _loadLinkedTransactions();
    } catch (e) {
      print('Error loading appointment: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar cita: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Método para cargar transacciones vinculadas
  Future<void> _loadLinkedTransactions() async {
    if (_appointment == null) return;

    setState(() => _isLoadingTransactions = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final transactions =
          await dbService.getTransactionsForAppointment(_appointment!.id);

      setState(() {
        _linkedTransactions = transactions;
        _isLoadingTransactions = false;
      });

      // Actualizar el estado de pago si es necesario
      await _updatePaymentStatusIfNeeded();
    } catch (e) {
      print('Error loading linked transactions: $e');
      setState(() => _isLoadingTransactions = false);
    }
  }

  // Nuevo método para actualizar el estado cuando hay pagos
  Future<void> _updatePaymentStatusIfNeeded() async {
    if (_appointment == null) return;

    // Si hay transacciones vinculadas y el estado es "pendiente de cobro"
    if (_linkedTransactions.isNotEmpty &&
        _appointment!.status == AppointmentStatus.completed_unpaid) {
      try {
        final dbService = Provider.of<DatabaseService>(context, listen: false);

        // Actualizar a completed_paid
        final updatedAppointment = _appointment!.copyWith(
          status: AppointmentStatus.completed_paid,
          updatedAt: DateTime.now(),
        );

        await dbService.updateAppointment(updatedAppointment);
        await _loadAppointment();
      } catch (e) {
        print('Error updating payment status: $e');
      }
    }
  }

  Future<void> _updateAppointmentStatus(AppointmentStatus newStatus) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Update appointment
      final updatedAppointment = _appointment!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await dbService.updateAppointment(updatedAppointment);

      // If cancelled, cancel notification
      if (newStatus == AppointmentStatus.cancelled) {
        try {
          final notificationService = Provider.of<NotificationService>(
            context,
            listen: false,
          );
          await notificationService.cancelAppointmentReminder(_appointment!.id);
        } catch (notificationError) {
          print('Error al cancelar notificación: $notificationError');
          // No mostramos error al usuario ya que la cita se actualizó correctamente
        }
      }

      // Reload appointment
      await _loadAppointment();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado de cita actualizado a ${_statusToString(updatedAppointment.status)}',
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error updating appointment: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar cita: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Método para "Completar y Cobrar"
  Future<void> _completeAndChargeAppointment() async {
    // Primero completamos la cita
    try {
      setState(() => _isProcessing = true);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Actualizar la cita a "completada pendiente de pago"
      final updatedAppointment = _appointment!.copyWith(
        status: AppointmentStatus.completed_unpaid,
        updatedAt: DateTime.now(),
      );

      await dbService.updateAppointment(updatedAppointment);

      // Recargar la cita actualizada
      await _loadAppointment();

      // Navegar a la pantalla de transacciones con la pestaña de nueva transacción seleccionada
      Navigator.of(context).pushNamed(
        AppRoutes.financial,
        arguments: {
          'initialTab': 2, // Índice de la pestaña "Nueva Transacción"
          'preSelectedClient': _appointment!.clientId,
          'preSelectedAppointment': _appointment!.id,
        },
      ).then((_) {
        // Al volver, recargar las transacciones vinculadas
        _loadLinkedTransactions();
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al completar la cita: ${e.toString()}'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.completed_unpaid:
        return 'Completada - Pendiente de cobro';
      case AppointmentStatus.completed_paid:
        return 'Completada - Pagada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
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

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppTheme.primaryColor;
      case AppointmentStatus.completed_unpaid:
        return AppTheme.warningColor; // Color naranja para pendiente de cobro
      case AppointmentStatus.completed_paid:
        return AppTheme.successColor; // Verde para pagada
      case AppointmentStatus.cancelled:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.event_available;
      case AppointmentStatus.completed_unpaid:
        return Icons.payment_outlined; // Icono de pago pendiente
      case AppointmentStatus.completed_paid:
        return Icons.payments; // Icono de pagado
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading
              ? 'Detalles de Cita'
              : _appointment != null
                  ? 'Cita: ${DateFormat('dd/MM/yyyy').format(_appointment!.date)}'
                  : 'Detalles de Cita',
          style: AppTheme.subheadingStyle,
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              // Intenta usar la navegación anidada si está disponible
              Provider.of<NavigationState>(context, listen: false).goBack();
            } catch (e) {
              // Si falla, usa la navegación estándar
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (_appointment != null &&
              _appointment!.status == AppointmentStatus.scheduled)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'complete') {
                  _updateAppointmentStatus(AppointmentStatus.completed_unpaid);
                } else if (value == 'cancel') {
                  _updateAppointmentStatus(AppointmentStatus.cancelled);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor),
                      SizedBox(width: 8),
                      Text('Marcar como Completada'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text('Cancelar Cita'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Información General'),
            Tab(text: 'Pagos'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _appointment == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cita no encontrada',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Información General
                        _buildCombinedInfoTab(),

                        // Tab 2: Pagos
                        _buildPaymentsTab(),
                      ],
                    ),

                    // Loading overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      // Botones flotantes para acciones principales
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  // Método para construir los botones flotantes según el estado
  Widget? _buildFloatingActionButtons() {
    if (_isLoading || _appointment == null) {
      return null;
    }

    // Caso 1: Cita programada -> mostrar tres botones
    if (_appointment!.status == AppointmentStatus.scheduled) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón: COMPLETAR
          FloatingActionButton.extended(
            heroTag: 'completeBtn',
            onPressed: _isProcessing
                ? null
                : () => _updateAppointmentStatus(
                    AppointmentStatus.completed_unpaid),
            label: const Text('Completar'),
            icon: const Icon(Icons.check),
            backgroundColor: AppTheme.successColor,
          ),
          const SizedBox(height: 12),

          // Botón: COMPLETAR Y COBRAR
          FloatingActionButton.extended(
            heroTag: 'chargeBtn',
            onPressed: _isProcessing ? null : _completeAndChargeAppointment,
            label: const Text('Completar y Cobrar'),
            icon: const Icon(Icons.payment),
            backgroundColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),

          // *** NUEVO BOTÓN: CANCELAR CITA ***
          FloatingActionButton.extended(
            heroTag: 'cancelBtn',
            onPressed: _isProcessing
                ? null
                : () => _updateAppointmentStatus(AppointmentStatus.cancelled),
            label: const Text('Cancelar Cita'),
            icon: const Icon(Icons.cancel),
            backgroundColor: AppTheme.errorColor,
          ),
        ],
      );
    }

    // Caso 2: Cita completada pero pendiente de pago - mostrar botón de registro de pago
    else if (_appointment!.status == AppointmentStatus.completed_unpaid) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.financial,
          arguments: {
            'initialTab': 2, // Nueva Transacción
            'preSelectedClient': _appointment!.clientId,
            'preSelectedAppointment': _appointment!.id,
          },
        ).then((_) => _loadLinkedTransactions()),
        label: const Text('Registrar Pago'),
        icon: const Icon(Icons.payment),
        backgroundColor: AppTheme.warningColor,
      );
    }

    // Para otros estados, no mostrar botón
    return null;
  }

  // Tab 1: Información general combinada de la cita y tratamiento
  Widget _buildCombinedInfoTab() {
    if (_appointment == null) return SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====== Encabezado con el estado de la cita y un ícono ======
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícono con fondo circular
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(_appointment!.status).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(_appointment!.status),
                  color: _getStatusColor(_appointment!.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusToString(_appointment!.status),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_appointment!.status),
                  ),
                ),
              ),
            ],
          ),

          // Pequeña separación
          const SizedBox(height: 8),

          // ====== INFORMACIÓN DEL CLIENTE ======
          // Podemos usar ListTile para algo más compacto
          ListTile(
            contentPadding: EdgeInsets.zero, // quitar paddings extras
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _client?.photoUrl != null
                  ? NetworkImage(_client!.photoUrl!)
                  : null,
              child: _client?.photoUrl == null
                  ? Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            title: Text(
              _client?.fullName ?? 'Cliente desconocido',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _client?.phone ?? 'Sin teléfono',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing:
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // Navegar a detalle de cliente
              if (_client != null) {
                Navigator.of(context).pushNamed(
                  AppRoutes.clientDetails,
                  arguments: {'clientId': _client!.id},
                );
              }
            },
          ),

          // Notas médicas (si las hay), con diseño más comprimido
          if (_client?.medicalNotes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Notas médicas: ${_client!.medicalNotes}',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[800]),
              ),
            ),
          ],

          const Divider(height: 24, thickness: 1),

          // ====== FECHA Y HORA ======
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event, color: AppTheme.primaryColor),
            title: Text(
              DateFormat('EEEE, d MMMM, yyyy', 'es').format(_appointment!.date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${_appointment!.startTime.format(context)} - '
              '${_appointment!.endTime.format(context)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

          const Divider(height: 24, thickness: 1),

          // ====== TIPO DE TRATAMIENTO ======
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.medical_services, color: AppTheme.primaryColor),
            title: Text(
              'Tratamiento: ${_appointment!.treatmentType}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          const Divider(height: 24, thickness: 1),

          // ====== MOTIVO DE LA CITA ======
          if (_appointment!.reason.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.description, color: AppTheme.primaryColor),
              title: Text(
                'Motivo',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _appointment!.reason,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),

          // ====== NOTAS ADICIONALES ======
          if ((_appointment!.notes?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Notas Adicionales:\n${_appointment!.notes!}',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ),

          const Divider(height: 24, thickness: 1),

          // ====== TERAPEUTA ======
          if (_therapist != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _therapist!.photoUrl != null
                    ? NetworkImage(_therapist!.photoUrl!)
                    : null,
                child: _therapist!.photoUrl == null
                    ? Icon(Icons.spa, color: AppTheme.primaryColor)
                    : null,
              ),
              title: Text(
                _therapist!.fullName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _therapist!.phone ?? 'Sin teléfono',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

          // Deja un margen al final para no chocar con FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Tab 2: Información de pagos
  Widget _buildPaymentsTab() {
    return RefreshIndicator(
      onRefresh: _loadLinkedTransactions,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado de Pago
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Estado de Pago',
                          style: AppTheme.subheadingStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    _isLoadingTransactions
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : _linkedTransactions.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pago Pendiente',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Esta cita no tiene pagos registrados',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).pushNamed(
                                        AppRoutes.financial,
                                        arguments: {
                                          'initialTab': 2, // Nueva Transacción
                                          'preSelectedClient':
                                              _appointment!.clientId,
                                          'preSelectedAppointment':
                                              _appointment!.id,
                                        },
                                      ).then((_) => _loadLinkedTransactions()),
                                      icon: const Icon(Icons.payment),
                                      label: const Text('Registrar Pago'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.orange,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.successColor
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppTheme.successColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Pagado',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successColor
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${_linkedTransactions.length} pago(s)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...List.generate(
                                    _linkedTransactions.length,
                                    (index) => _buildPaymentCard(
                                        _linkedTransactions[index], index),
                                  ),
                                ],
                              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón para registrar nuevo pago (solo si ya hay pagos)
            if (_linkedTransactions.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.financial,
                    arguments: {
                      'initialTab': 2, // Nueva Transacción
                      'preSelectedClient': _appointment!.clientId,
                      'preSelectedAppointment': _appointment!.id,
                    },
                  ).then((_) => _loadLinkedTransactions()),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar Pago Adicional'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 80), // Espacio para botón flotante
          ],
        ),
      ),
    );
  }

  // Tarjeta de pago individual
  Widget _buildPaymentCard(TransactionModel transaction, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.successColor.withOpacity(0.1),
                  child: Icon(
                    Icons.payments_outlined,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pago ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM, yyyy - HH:mm', 'es')
                            .format(transaction.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.payment,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Método: ${_getPaymentMethodName(transaction.method)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Completado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            if (transaction.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Nota: ${transaction.notes}',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
