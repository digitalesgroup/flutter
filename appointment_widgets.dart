//lib/widgets/appointment_widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

// Appointment List Item Widget
class AppointmentListItem extends StatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const AppointmentListItem({required this.appointment, required this.onTap});

  @override
  _AppointmentListItemState createState() => _AppointmentListItemState();
}

class _AppointmentListItemState extends State<AppointmentListItem> {
  UserModel? _client;
  UserModel? _therapist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Load client and therapist
      final client = await dbService.getUser(widget.appointment.clientId);
      final therapist = await dbService.getUser(widget.appointment.employeeId);

      if (mounted) {
        setState(() {
          _client = client;
          _therapist = therapist;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format time
    final startTime = widget.appointment.startTime.format(context);

    // Status color
    Color statusColor;
    switch (widget.appointment.status) {
      case AppointmentStatus.scheduled:
        statusColor = Colors.blue;
        break;
      case AppointmentStatus.completed_unpaid:
        statusColor = Colors.green;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: _isLoading
            ? const CircleAvatar(child: Icon(Icons.person))
            : CircleAvatar(
                backgroundImage: _client?.photoUrl != null
                    ? NetworkImage(_client!.photoUrl!)
                    : null,
                child: _client?.photoUrl == null
                    ? Text(_client?.name[0] ?? '?')
                    : null,
              ),
        title: _isLoading
            ? const Text('Cargando...')
            : Text(_client?.fullName ?? 'Cliente'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$startTime - ${widget.appointment.treatmentType}'),
            Text(
              _isLoading
                  ? 'Cargando terapeuta...'
                  : 'Terapeuta: ${_therapist?.fullName ?? 'Desconocido'}',
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            _getStatusText(widget.appointment.status),
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ),
        isThreeLine: true,
        onTap: widget.onTap,
      ),
    );
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.completed_unpaid:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }
}

// Appointment Status Card Widget
class AppointmentStatusCard extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentStatusCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        statusColor = Colors.blue;
        statusText = 'Programada';
        statusIcon = Icons.schedule;
        break;
      case AppointmentStatus.completed_unpaid:
        statusColor = Colors.green;
        statusText = 'Completada';
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelada';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado de la Cita',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Appointment Time Slot Widget
class AppointmentTimeSlot extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String title;
  final String? subtitle;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppointmentTimeSlot({
    required this.startTime,
    required this.endTime,
    required this.title,
    this.subtitle,
    this.isAvailable = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeText =
        '${startTime.format(context)} - ${endTime.format(context)}';

    return Card(
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAvailable
              ? (isSelected ? Theme.of(context).primaryColor : Colors.green)
              : Colors.red,
          child: Icon(
            isAvailable ? Icons.access_time : Icons.block,
            color: Colors.white,
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeText),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
        enabled: isAvailable,
        onTap: isAvailable ? onTap : null,
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              )
            : null,
      ),
    );
  }
}

// Week Calendar Widget
class WeekCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const WeekCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get start of week (Monday)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the first day of the current week (Monday)
    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));

    // Create a list of 7 days starting from Monday
    final days = List.generate(
      7,
      (index) => firstDayOfWeek.add(Duration(days: index)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Semana del ${DateFormat('d MMM', 'es').format(firstDayOfWeek)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'al ${DateFormat('d MMM', 'es').format(days.last)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;
                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;

                return DayItem(
                  date: day,
                  isSelected: isSelected,
                  isToday: isToday,
                  onTap: () => onDateSelected(day),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Day Item Widget for Week Calendar
class DayItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const DayItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get day of week
    final dayName = DateFormat('E', 'es').format(date);

    // Get day number
    final dayNumber = date.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        width: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isToday ? Colors.grey.withOpacity(0.2) : null),
          borderRadius: BorderRadius.circular(16),
          border: isToday && !isSelected
              ? Border.all(color: Theme.of(context).primaryColor)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isSelected
                  ? Colors.white
                  : (isToday
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withOpacity(0.2)),
              child: Text(
                dayNumber,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isToday ? Colors.white : Colors.black),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Month Calendar Header Widget
class MonthCalendarHeader extends StatelessWidget {
  final DateTime displayedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthCalendarHeader({
    required this.displayedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy', 'es').format(displayedMonth).capitalize(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings (for month names)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + substring(1);
  }
}
