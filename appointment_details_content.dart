// lib/widgets/appointment_details_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../app_theme.dart';
import '../routes.dart';

class AppointmentDetailsContent extends StatefulWidget {
  final String appointmentId;
  final Function onAppointmentUpdated;

  const AppointmentDetailsContent({
    Key? key,
    required this.appointmentId,
    required this.onAppointmentUpdated,
  }) : super(key: key);

  @override
  _AppointmentDetailsContentState createState() =>
      _AppointmentDetailsContentState();
}

class _AppointmentDetailsContentState extends State<AppointmentDetailsContent> {
  AppointmentModel? _appointment;
  UserModel? _client;
  UserModel? _therapist;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Para transacciones vinculadas
  bool _isLoadingTransactions = false;
  List<TransactionModel> _linkedTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Cargar la cita
      final appointment = await dbService.getAppointment(widget.appointmentId);

      // Cargar cliente y terapeuta
      final client = await dbService.getUser(appointment.clientId);
      final therapist = await dbService.getUser(appointment.employeeId);

      if (!mounted) return;

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

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar cita: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Método para cargar transacciones vinculadas
  Future<void> _loadLinkedTransactions() async {
    if (_appointment == null || !mounted) return;

    setState(() => _isLoadingTransactions = true);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final transactions =
          await dbService.getTransactionsForAppointment(_appointment!.id);

      if (!mounted) return;

      setState(() {
        _linkedTransactions = transactions;
        _isLoadingTransactions = false;
      });

      // Actualizar el estado de pago si es necesario
      await _updatePaymentStatusIfNeeded();
    } catch (e) {
      print('Error loading linked transactions: $e');

      if (!mounted) return;

      setState(() => _isLoadingTransactions = false);
    }
  }

  // Método para actualizar el estado cuando hay pagos
  Future<void> _updatePaymentStatusIfNeeded() async {
    if (_appointment == null || !mounted) return;

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

        if (!mounted) return;

        setState(() {
          _appointment = updatedAppointment;
        });

        // Notificar que hubo un cambio
        widget.onAppointmentUpdated();
      } catch (e) {
        print('Error updating payment status: $e');
      }
    }
  }

  Future<void> _updateAppointmentStatus(AppointmentStatus newStatus) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Actualizar cita
      final updatedAppointment = _appointment!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await dbService.updateAppointment(updatedAppointment);

      // Actualizar directamente el modelo local para mostrar el cambio
      if (mounted) {
        setState(() {
          _appointment = updatedAppointment;
          _isProcessing = false;
        });
      }

      // Cargar solo las transacciones relacionadas sin recargar todo
      if (mounted) {
        _loadLinkedTransactions();
      }

      // Notificar que hubo un cambio para actualizar el calendario
      widget.onAppointmentUpdated();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado de cita actualizado a ${_statusToString(newStatus)}',
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating appointment: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar cita: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Método para "Completar y Cobrar"
  Future<void> _completeAndChargeAppointment() async {
    if (!mounted) return;

    try {
      setState(() => _isProcessing = true);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Actualizar la cita a "completada pendiente de pago"
      final updatedAppointment = _appointment!.copyWith(
        status: AppointmentStatus.completed_unpaid,
        updatedAt: DateTime.now(),
      );

      await dbService.updateAppointment(updatedAppointment);

      // Actualizar el modelo local
      if (!mounted) return;

      setState(() {
        _appointment = updatedAppointment;
        _isProcessing = false;
      });

      // Notificar cambio para actualizar el calendario
      widget.onAppointmentUpdated();

      // Cerrar el popup y navegar
      Navigator.of(context).pop(true);

      // Navegar a la pantalla de transacciones
      Navigator.of(context).pushNamed(
        AppRoutes.financial,
        arguments: {
          'initialTab': 2,
          'preSelectedClient': _appointment!.clientId,
          'preSelectedAppointment': _appointment!.id,
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al completar la cita: ${e.toString()}'),
        backgroundColor: Colors.red,
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
        return Colors.orange;
      case AppointmentStatus.completed_paid:
        return AppTheme.successColor;
      case AppointmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.event_available;
      case AppointmentStatus.completed_unpaid:
        return Icons.payment_outlined;
      case AppointmentStatus.completed_paid:
        return Icons.payments;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // <-- Añade SingleChildScrollView HERE wrapping the main Column
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de título con controles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      _isLoading
                          ? 'Detalles de Cita'
                          : _appointment != null
                              ? 'Cita: ${DateFormat('dd/MM/yyyy').format(_appointment!.date)}'
                              : 'Detalles de Cita',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Contenido principal con scroll
          // Removed maxHeight constraint from here
          Container(
            // constraints: BoxConstraints(  <-- REMOVE THIS Constraint
            //   maxHeight: MediaQuery.of(context).size.height * 0.7,
            // ),
            child: _isLoading
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
                                color: Colors.grey.shade600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          // Vista principal con scroll
                          _buildCombinedView(),

                          // Overlay de carga
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
          ),

          // Botones de acción en la parte inferior
          if (!_isLoading && _appointment != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildCombinedView() {
    if (_appointment == null) return SizedBox.shrink();

    return SingleChildScrollView(
      // Keep this SingleChildScrollView for internal content scrolling
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado de la cita - Con diseño mejorado
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: _getStatusColor(_appointment!.status).withOpacity(0.1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(_appointment!.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Resto del contenido
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente e información principal...
                _buildInfoItem(
                  icon: Icons.person,
                  title: _client?.fullName ?? 'Cliente desconocido',
                  subtitle: _client?.phone ?? 'Sin teléfono',
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey.shade400),
                  onTap: () {
                    if (_client != null) {
                      Navigator.of(context).pop(); // Cerrar popup
                      Navigator.of(context).pushNamed(
                        AppRoutes.clientDetails,
                        arguments: {'clientId': _client!.id},
                      );
                    }
                  },
                ),

                // Notas médicas
                if (_client?.medicalNotes?.isNotEmpty ?? false) ...[
                  Container(
                    margin: EdgeInsets.only(left: 34, top: 0, bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medical_information,
                            color: Colors.blue.shade300, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _client!.medicalNotes!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Fecha y hora
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  title: DateFormat('EEEE, d MMMM, yyyy', 'es')
                      .format(_appointment!.date),
                  subtitle:
                      '${_appointment!.startTime.format(context)} - ${_appointment!.endTime.format(context)}',
                ),

                // Tipo de tratamiento
                _buildInfoItem(
                  icon: Icons.medical_services,
                  title: 'Tratamiento: ${_appointment!.treatmentType}',
                ),

                // Motivo de la cita
                if (_appointment!.reason.isNotEmpty)
                  _buildInfoItem(
                    icon: Icons.description,
                    title: 'Motivo',
                    subtitle: _appointment!.reason,
                  ),

                // Notas adicionales
                if ((_appointment!.notes?.isNotEmpty ?? false))
                  _buildInfoItem(
                    icon: Icons.note,
                    title: 'Notas adicionales',
                    subtitle: _appointment!.notes!,
                    isMultiline: true,
                  ),

                // Terapeuta
                if (_therapist != null)
                  _buildInfoItem(
                    icon: Icons.spa,
                    title: _therapist!.fullName,
                    subtitle: _therapist!.phone ?? 'Sin teléfono',
                  ),

                // Sección de PAGOS con título destacado
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Información de Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Estado de Pago
                _isLoadingTransactions
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pago Pendiente',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Esta cita no tiene pagos registrados',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Indicador de pagado
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppTheme.successColor.withOpacity(0.3),
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pagado',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${_linkedTransactions.length} pago(s) registrado(s)',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
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
        ],
      ),
    );
  }

  // Elemento de información reutilizable
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isMultiline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: isMultiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(width: 4),
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: isMultiline ? 1.4 : 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // Botones de acción según el estado
  Widget _buildActionButtons() {
    if (_appointment!.status == AppointmentStatus.scheduled) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.check, size: 18),
              label: const Text('Completar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _isProcessing
                  ? null
                  : () => _updateAppointmentStatus(
                      AppointmentStatus.completed_unpaid),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.payments, size: 18),
              label: const Text('Completar y Cobrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _isProcessing ? null : _completeAndChargeAppointment,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44,
            width: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.red,
                elevation: 0,
              ),
              onPressed: _isProcessing
                  ? null
                  : () => _updateAppointmentStatus(AppointmentStatus.cancelled),
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      );
    } else if (_appointment!.status == AppointmentStatus.completed_unpaid) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.payment, size: 18),
          label: const Text('Registrar Pago'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.of(context).pop(true); // Cerrar con resultado true
            Navigator.of(context).pushNamed(
              AppRoutes.financial,
              arguments: {
                'initialTab': 2, // Nueva Transacción
                'preSelectedClient': _appointment!.clientId,
                'preSelectedAppointment': _appointment!.id,
              },
            );
          },
        ),
      );
    }

    // Para estados cancelados o completados-pagados, solo botón de cerrar
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        child: const Text('Cerrar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
