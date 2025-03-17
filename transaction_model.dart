//lib/models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { payment, debt }

enum PaymentMethod {
  cash,
  card,
  transfer,
  unknown
} // Added unknown for default case

enum TransactionStatus { completed, pending }

class TransactionModel {
  final String id;
  final String clientId;
  final String? serviceId;
  final String? employeeId;
  final List<String>?
      appointmentIds; // Cambiado de appointmentId a appointmentIds (lista)
  final double amount;
  final TransactionType type;
  final PaymentMethod method;
  final TransactionStatus status;
  final DateTime date;
  final String? notes;
  final String? voucherNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String description;

  TransactionModel({
    required this.id,
    required this.clientId,
    this.serviceId,
    this.employeeId,
    this.appointmentIds, // Modificado para ser una lista
    required this.amount,
    required this.type,
    required this.method,
    this.status = TransactionStatus.completed,
    required this.date,
    this.notes,
    this.voucherNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.description,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Obtener appointmentIds como lista
    List<String>? appointmentIds;
    if (data['appointmentIds'] != null) {
      appointmentIds = List<String>.from(data['appointmentIds']);
    } else if (data['appointmentId'] != null && data['appointmentId'] != '') {
      // Compatibilidad con versiones anteriores - migrar appointmentId a appointmentIds
      appointmentIds = [data['appointmentId']];
    }

    return TransactionModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      serviceId: data['serviceId'],
      employeeId: data['employeeId'],
      appointmentIds: appointmentIds,
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: _typeFromString(data['type'] ?? 'income'),
      method: _methodFromString(data['method'] ?? 'cash'),
      status: _statusFromString(data['status'] ?? 'completed'),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      voucherNumber: data['voucherNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      description: data['description'] ?? 'Sin descripción',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'serviceId': serviceId,
      'employeeId': employeeId,
      'appointmentIds': appointmentIds, // Ahora guarda la lista de IDs
      'amount': amount,
      'type': _typeToString(type),
      'method': _methodToString(method),
      'status': _statusToString(status),
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'voucherNumber': voucherNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
    };
  }

  static TransactionType _typeFromString(String type) {
    switch (type) {
      case 'expense':
        return TransactionType.debt;
      case 'income':
      default:
        return TransactionType.payment;
    }
  }

  static String _typeToString(TransactionType type) {
    switch (type) {
      case TransactionType.debt:
        return 'expense';
      case TransactionType.payment:
        return 'income';
      default:
        return 'income';
    }
  }

  static PaymentMethod _methodFromString(String method) {
    switch (method) {
      case 'card':
        return PaymentMethod.card;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.unknown;
    }
  }

  static String _methodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.unknown:
        return 'unknown';
      default:
        return 'unknown';
    }
  }

  static TransactionStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
      default:
        return TransactionStatus.completed;
    }
  }

  static String _statusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.completed:
        return 'completed';
    }
  }

  // Método para verificar si la transacción está vinculada a citas
  bool get hasAppointments =>
      appointmentIds != null && appointmentIds!.isNotEmpty;

  TransactionModel copyWith({
    String? id,
    String? clientId,
    String? serviceId,
    String? employeeId,
    List<String>? appointmentIds, // Modificado para ser una lista
    double? amount,
    TransactionType? type,
    PaymentMethod? method,
    TransactionStatus? status,
    DateTime? date,
    String? notes,
    String? voucherNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      serviceId: serviceId ?? this.serviceId,
      employeeId: employeeId ?? this.employeeId,
      appointmentIds: appointmentIds ?? this.appointmentIds,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      method: method ?? this.method,
      status: status ?? this.status,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }
}
