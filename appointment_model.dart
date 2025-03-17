//lib/models/appointment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

enum AppointmentStatus {
  scheduled,
  completed_unpaid,
  completed_paid,
  cancelled
}

class AppointmentModel {
  final String id;
  final String clientId;
  final String employeeId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final AppointmentStatus status;
  final String reason;
  final String treatmentType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? transactionIds; // Nuevo campo para IDs de transacciones

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.scheduled,
    required this.reason,
    required this.treatmentType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.transactionIds, // Agregado al constructor
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert Firestore Timestamp to DateTime
    DateTime dateTime = (data['date'] as Timestamp).toDate();

    // Convert stored integers to TimeOfDay
    TimeOfDay _timeFromMap(Map<String, dynamic> timeMap) {
      return TimeOfDay(
        hour: timeMap['hour'] ?? 0,
        minute: timeMap['minute'] ?? 0,
      );
    }

    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      date: dateTime,
      startTime: _timeFromMap(data['startTime'] ?? {'hour': 0, 'minute': 0}),
      endTime: _timeFromMap(data['endTime'] ?? {'hour': 0, 'minute': 0}),
      status: _statusFromString(data['status'] ?? 'scheduled'),
      reason: data['reason'] ?? '',
      treatmentType: data['treatmentType'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      // Nuevo: extraer lista de IDs de transacciones
      transactionIds: data['transactionIds'] != null
          ? List<String>.from(data['transactionIds'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    // Convert TimeOfDay to map for storage
    Map<String, int> _timeToMap(TimeOfDay time) {
      return {'hour': time.hour, 'minute': time.minute};
    }

    return {
      'clientId': clientId,
      'employeeId': employeeId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'startTime': _timeToMap(startTime),
      'endTime': _timeToMap(endTime),
      'status': _statusToString(status),
      'reason': reason,
      'treatmentType': treatmentType,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'transactionIds': transactionIds ?? [], // Nuevo: guardar lista de IDs
    };
  }

  // Convert to Syncfusion Appointment
  Appointment toSyncfusionAppointment({Color? color}) {
    // Combine date with TimeOfDay to create full DateTime objects
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    return Appointment(
      id: id,
      subject: treatmentType,
      notes: reason,
      location: notes,
      startTime: startDateTime,
      endTime: endDateTime,
      color: color ?? _getDefaultColor(),
      isAllDay: false,
    );
  }

  Color _getDefaultColor() {
    switch (treatmentType) {
      case 'Masajes':
        return Colors.blue;
      case 'Tratamiento Facial':
        return Colors.green;
      case 'Tratamiento Corporal':
        return Colors.purple;
      case 'Post Operatorio':
        return Colors.orange;
      case 'Camara de Bronceado':
        return Colors.amber;
      case 'Depilacion':
        return Colors.pink;
      case 'Botox':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }

  static AppointmentStatus _statusFromString(String status) {
    switch (status) {
      case 'completed_paid':
        return AppointmentStatus.completed_paid;
      case 'completed_unpaid':
        return AppointmentStatus.completed_unpaid;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'scheduled':
      default:
        return AppointmentStatus.scheduled;
    }
  }

  static String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.completed_paid:
        return 'completed_paid';
      case AppointmentStatus.completed_unpaid:
        return 'completed_unpaid';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.scheduled:
      default:
        return 'scheduled';
    }
  }

  // Método para verificar si la cita está vinculada a alguna transacción
  bool get hasTransactions =>
      transactionIds != null && transactionIds!.isNotEmpty;

  // Método para verificar si la cita está completada y pagada
  bool get isFullyPaid =>
      status == AppointmentStatus.completed_unpaid && hasTransactions;

  // Método para verificar si la cita está completada pero no pagada
  bool get isPendingPayment =>
      status == AppointmentStatus.completed_unpaid && !hasTransactions;

  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? employeeId,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    AppointmentStatus? status,
    String? reason,
    String? treatmentType,
    String? notes,
    DateTime? updatedAt,
    List<String>? transactionIds, // Añadido al copyWith
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      treatmentType: treatmentType ?? this.treatmentType,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      transactionIds:
          transactionIds ?? this.transactionIds, // Copiamos transactionIds
    );
  }
}
