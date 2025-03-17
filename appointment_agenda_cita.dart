// lib/screens/appointment_agenda_cita.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../app_theme.dart';
import 'appointment_detalles_cita.dart';
import '../widgets/appointment_dialog.dart';
import '../widgets/custom_popup_dialog.dart';
import '../widgets/appointment_details_content.dart';

// Appointment Calendar Screen
class AppointmentListScreen extends StatefulWidget {
  // Agregamos el callback como parámetro opcional
  final Function(String)? onAppointmentSelected;

  AppointmentListScreen({Key? key, this.onAppointmentSelected})
      : super(key: key);

  @override
  _AppointmentListScreenState createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AppointmentModel> _appointments = [];
  List<UserModel> _therapists = [];
  String? _selectedTherapistId;
  bool _isLoading = true;

  // Opciones de visualización: 0=Semana, 1=Día, 2=Mes
  int _viewType = 0;

  // Controlador para el calendario
  final CalendarController _calendarController = CalendarController();

  // Variable para controlar el tooltip
  Appointment? _selectedAppointment;
  Offset _tapPosition = Offset.zero;
  OverlayEntry? _currentOverlayEntry;

  @override
  void initState() {
    super.initState();
    _calendarController.view = CalendarView.week;
    _loadInitialData();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Cargar terapeutas
      final therapists = await dbService.getTherapists();

      // Cargar citas
      await _loadAppointments();

      setState(() {
        _therapists = therapists;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar citas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      DateTime startDate;
      DateTime endDate;

      // Determinar rango de fechas según la vista actual
      switch (_getCurrentCalendarView()) {
        case CalendarView.day:
          // Para la vista diaria, solo cargamos el día seleccionado
          startDate = DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day);
          endDate = DateTime(_selectedDate.year, _selectedDate.month,
              _selectedDate.day, 23, 59, 59);
          break;

        case CalendarView.week:
          // Para la vista semanal, calculamos desde el primer día de la semana hasta el último
          // Primer día (Lunes = 1, Domingo = 7)
          final firstDayOfWeek =
              _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          startDate = DateTime(
              firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
          // Último día (domingo)
          endDate = startDate
              .add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          break;

        case CalendarView.month:
          // Para la vista mensual, calculamos desde el primer día del mes hasta el último
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          // Último día del mes (calculando el día 0 del mes siguiente)
          endDate = DateTime(
              _selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
          break;

        default:
          // Por defecto, usamos la vista semanal
          final firstDayOfWeek =
              _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          startDate = DateTime(
              firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
          endDate = startDate
              .add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      }

      print(
          'Cargando citas desde $startDate hasta $endDate para vista ${_getCurrentCalendarView()}');

      // Carga todas las citas del rango
      final loadedAppointments = await dbService.getAppointmentsBetweenDates(
        startDate,
        endDate,
        _selectedTherapistId,
      );

      if (mounted) {
        setState(() {
          _appointments = loadedAppointments;
          _isLoading = false;
        });

        print('Citas cargadas: ${_appointments.length}');

        // Si no hay citas en este rango, mostrar un mensaje
        if (_appointments.isEmpty) {
          print('No hay citas en el rango seleccionado');
        }
      }
    } catch (e) {
      print('Error cargando citas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar citas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _filterByTherapist(String? therapistId) async {
    setState(() {
      _selectedTherapistId = therapistId;
    });

    await _loadAppointments();
  }

  // Convertir AppointmentModel a Appointment para SfCalendar
  List<Appointment> _getAppointmentsForSfCalendar() {
    final appointments = _appointments.map((app) {
      DateTime startDateTime = DateTime(
        app.date.year,
        app.date.month,
        app.date.day,
        app.startTime.hour,
        app.startTime.minute,
      );

      DateTime endDateTime = DateTime(
        app.date.year,
        app.date.month,
        app.date.day,
        app.endTime.hour,
        app.endTime.minute,
      );

      final clientName = _getClientName(app.clientId);
      final subject = "${app.treatmentType} - ${clientName}";

      return Appointment(
        id: app.id,
        subject: subject,
        notes: app.reason,
        location: clientName,
        startTime: startDateTime,
        endTime: endDateTime,
        color: _getColorForTreatment(app.treatmentType),
        isAllDay: false,
      );
    }).toList();

    print('Total appointments para SfCalendar: ${appointments.length}');
    return appointments;
  }

  String _getClientName(String clientId) {
    try {
      final client = _therapists.firstWhere(
        (t) => t.id == clientId,
        orElse: () => UserModel(
          id: '',
          name: '',
          lastName: 'Cliente',
          role: UserRole.client,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return client.fullName;
    } catch (e) {
      return 'Cliente';
    }
  }

  Color _getColorForTreatment(String treatmentType) {
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

  // Función para verificar si un AppointmentModel coincide con un Appointment de SfCalendar
  AppointmentModel? _findAppointmentModelFromSfAppointment(
      Appointment sfAppointment) {
    try {
      return _appointments.firstWhere(
        (app) {
          final startDateTime = DateTime(
            app.date.year,
            app.date.month,
            app.date.day,
            app.startTime.hour,
            app.startTime.minute,
          );

          // Si el ID está disponible, usarlo directamente
          if (sfAppointment.id != null &&
              sfAppointment.id.toString() == app.id) {
            return true;
          }

          // Si no, comparar por horario y asunto
          final sfSubject = sfAppointment.subject ?? '';
          return sfSubject.contains(app.treatmentType) &&
              startDateTime.isAtSameMomentAs(sfAppointment.startTime);
        },
      );
    } catch (e) {
      print('No se encontró el AppointmentModel correspondiente: $e');
      return null;
    }
  }

  CalendarView _getCurrentCalendarView() {
    switch (_viewType) {
      case 0:
        return CalendarView.week;
      case 1:
        return CalendarView.day;
      case 2:
        return CalendarView.month;
      default:
        return CalendarView.week;
    }
  }

  IconData _getViewIcon() {
    switch (_viewType) {
      case 0:
        return Icons.view_week;
      case 1:
        return Icons.view_day;
      case 2:
        return Icons.calendar_view_month;
      default:
        return Icons.view_week;
    }
  }

  String _getViewText() {
    switch (_viewType) {
      case 0:
        return 'Semana';
      case 1:
        return 'Día';
      case 2:
        return 'Mes';
      default:
        return 'Semana';
    }
  }

  // Widget para información rápida al pasar el cursor (hover)
  Widget _buildAppointmentTooltip(Appointment appointment) {
    final AppointmentModel? model =
        _findAppointmentModelFromSfAppointment(appointment);
    if (model == null) return Container();

    return Container(
      width: 300,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForTreatment(model.treatmentType),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                model.treatmentType,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getClientName(model.clientId),
                  style: TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                '${model.startTime.format(context)} - ${model.endTime.format(context)}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  model.reason,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text('Ver detalles'),
                onPressed: () {
                  _removeCurrentTooltip(); // Remove tooltip when "Ver detalles" is pressed
                  // Ir a la pantalla de detalles
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailsScreen(
                        appointmentId: model.id,
                      ),
                    ),
                  ).then((_) => _loadAppointments());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Función para mostrar el tooltip con información rápida
  void _showAppointmentQuickInfo(Appointment appointment, BuildContext context,
      {Offset? position}) {
    if (!mounted) return; // Evita ejecutar código en widget destruido

    final AppointmentModel? model =
        _findAppointmentModelFromSfAppointment(appointment);
    if (model == null) {
      _removeCurrentTooltip();
      return;
    }

    _removeCurrentTooltip();

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset offset = position ?? _tapPosition;

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + 20,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              _removeCurrentTooltip();
            },
            child: MouseRegion(
              onExit: (_) {
                _removeCurrentTooltip();
              },
              child: _buildAppointmentTooltip(appointment),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlayEntry!);
  }

  void _removeCurrentTooltip() {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null; // Reset the variable
    }
  }

  // Función para guardar la posición del tap
  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  // Función para comparar si dos fechas son el mismo día
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          // Botones de visualización siempre visibles
          Row(
            children: [
              // Botón de Día
              Tooltip(
                message: 'Vista diaria',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _viewType = 1;
                      _calendarController.view = CalendarView.day;
                    });
                    _loadAppointments();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _viewType == 1
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_day,
                          size: 20,
                          color: _viewType == 1
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Día',
                          style: TextStyle(
                            color: _viewType == 1
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: _viewType == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botón de Semana
              Tooltip(
                message: 'Vista semanal',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _viewType = 0;
                      _calendarController.view = CalendarView.week;
                    });
                    _loadAppointments();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _viewType == 0
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_week,
                          size: 20,
                          color: _viewType == 0
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Semana',
                          style: TextStyle(
                            color: _viewType == 0
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: _viewType == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botón de Mes
              Tooltip(
                message: 'Vista mensual',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _viewType = 2;
                      _calendarController.view = CalendarView.month;
                    });
                    _loadAppointments();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _viewType == 2
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_view_month,
                          size: 20,
                          color: _viewType == 2
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Mes',
                          style: TextStyle(
                            color: _viewType == 2
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: _viewType == 2
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Filter by therapist
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por terapeuta',
            onPressed: () {
              _showTherapistFilterDialog();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mostrar el diálogo en lugar de navegar a una nueva pantalla
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AppointmentDialog(
                initialDate: DateTime.now(),
                initialStartTime: TimeOfDay.now(),
              );
            },
          ).then((result) {
            // Si se creó una cita correctamente (result puede ser true o contener información sobre la cita)
            if (result != null) {
              if (result is Map<String, dynamic> &&
                  result.containsKey('date')) {
                // Si el diálogo nos devuelve la fecha, actualizamos la fecha seleccionada
                setState(() {
                  _selectedDate = result['date'];

                  // También actualizamos la vista del calendario para mostrar la fecha seleccionada
                  switch (_viewType) {
                    case 0: // Semana
                      _calendarController.displayDate = _selectedDate;
                      break;
                    case 1: // Día
                      _calendarController.displayDate = _selectedDate;
                      break;
                    case 2: // Mes
                      _calendarController.displayDate = _selectedDate;
                      break;
                  }
                });
              }
              // Recargamos las citas
              _loadAppointments();
            }
          });
        },
        tooltip: 'Añadir nueva cita',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filtro de terapeuta (si está seleccionado)
          if (_selectedTherapistId != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text('Filtro: '),
                  Chip(
                    label: Text(
                      _therapists
                          .firstWhere(
                            (t) => t.id == _selectedTherapistId,
                            orElse: () => UserModel(
                              id: '',
                              name: '',
                              lastName: 'Desconocido',
                              role: UserRole.therapist,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          )
                          .fullName,
                    ),
                    onDeleted: () {
                      _filterByTherapist(null);
                    },
                  ),
                ],
              ),
            ),

          // Calendario
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      // Si no hay citas, mostrar un mensaje
                      if (_appointments.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay citas para mostrar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pulse + para añadir una nueva cita',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Calendario Syncfusion con detector de gestos para el tooltip
                      Listener(
                        onPointerDown: (PointerDownEvent event) {
                          _tapPosition = event.position;
                        },
                        child: SfCalendar(
                          controller: _calendarController,
                          view: _getCurrentCalendarView(),
                          firstDayOfWeek: 1, // Lunes
                          showNavigationArrow: true,
                          showDatePickerButton: true,
                          allowViewNavigation: true,
                          showCurrentTimeIndicator: true,
                          dataSource: _AppointmentDataSource(
                              _getAppointmentsForSfCalendar()),
                          timeSlotViewSettings: const TimeSlotViewSettings(
                            startHour: 8,
                            endHour: 20,
                            timeFormat: 'HH:mm',
                            timeIntervalHeight: 60,
                            timeTextStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            dateFormat: 'd',
                            dayFormat: 'EEE',
                          ),
                          monthViewSettings: const MonthViewSettings(
                            showAgenda: true,
                            appointmentDisplayMode:
                                MonthAppointmentDisplayMode.appointment,
                            agendaViewHeight: 150,
                            appointmentDisplayCount: 4,
                          ),
                          headerStyle: CalendarHeaderStyle(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          todayHighlightColor: Theme.of(context).primaryColor,
                          selectionDecoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          appointmentTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          cellBorderColor: Colors.grey[300],

                          // Permitir arrastrar y soltar
                          allowDragAndDrop: true,
                          allowAppointmentResize: true,

                          // Handler para el hover en citas (para mostrar tooltip)
                          appointmentBuilder: (BuildContext context,
                              CalendarAppointmentDetails details) {
                            final Appointment appointment =
                                details.appointments.first;

                            return MouseRegion(
                              onEnter: (PointerEnterEvent event) {
                                _showAppointmentQuickInfo(appointment, context,
                                    position: event.position);
                              },
                              onExit: (_) {
                                _removeCurrentTooltip(); // Remove tooltip on mouse exit from appointment
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: appointment.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.all(2),
                                child: Center(
                                  child: Text(
                                    appointment.subject ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },

                          // Callback al arrastrar y soltar la cita
                          onDragEnd: (AppointmentDragEndDetails details) async {
                            final Appointment? draggedAppointment =
                                details.appointment as Appointment?;
                            final droppingTime = details.droppingTime;

                            if (draggedAppointment == null ||
                                droppingTime == null) {
                              return;
                            }

                            // Encontrar el AppointmentModel original
                            final originalApp =
                                _findAppointmentModelFromSfAppointment(
                                    draggedAppointment);
                            if (originalApp == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Error al actualizar cita: No se encontró la cita original'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Calculamos la duración original
                            final originalStart = DateTime(
                              originalApp.date.year,
                              originalApp.date.month,
                              originalApp.date.day,
                              originalApp.startTime.hour,
                              originalApp.startTime.minute,
                            );

                            final originalEnd = DateTime(
                              originalApp.date.year,
                              originalApp.date.month,
                              originalApp.date.day,
                              originalApp.endTime.hour,
                              originalApp.endTime.minute,
                            );

                            final duration =
                                originalEnd.difference(originalStart);

                            // Nueva fecha/hora de inicio (donde se soltó)
                            final newStart = droppingTime;
                            final newEnd = newStart.add(duration);

                            // Convertirlos a TimeOfDay
                            final newStartTime = TimeOfDay(
                              hour: newStart.hour,
                              minute: newStart.minute,
                            );

                            final newEndTime = TimeOfDay(
                              hour: newEnd.hour,
                              minute: newEnd.minute,
                            );

                            // Actualizamos el AppointmentModel
                            final updatedAppointment = originalApp.copyWith(
                              date: DateTime(
                                newStart.year,
                                newStart.month,
                                newStart.day,
                              ),
                              startTime: newStartTime,
                              endTime: newEndTime,
                              updatedAt: DateTime.now(),
                            );

                            try {
                              // Guardamos cambios en la base de datos
                              final dbService = Provider.of<DatabaseService>(
                                context,
                                listen: false,
                              );
                              await dbService
                                  .updateAppointment(updatedAppointment);

                              // Recargamos las citas para refrescar la vista
                              await _loadAppointments();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Cita actualizada correctamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              print('Error al actualizar cita: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error al actualizar cita: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },

                          // Callback al hacer tap en una cita o celda
                          onTap: (CalendarTapDetails details) {
                            if (details.targetElement ==
                                    CalendarElement.appointment &&
                                details.appointments != null &&
                                details.appointments!.isNotEmpty) {
                              _removeCurrentTooltip(); // Quitar tooltip si está visible

                              // Obtener el appointment seleccionado
                              final Appointment appointment =
                                  details.appointments![0];

                              // Encontrar el AppointmentModel correspondiente
                              final appModel =
                                  _findAppointmentModelFromSfAppointment(
                                      appointment);

                              if (appModel != null) {
                                // Mostrar la ventana emergente personalizada
                                CustomPopupDialog.show(
                                  context: context,
                                  barrierDismissible: false,
                                  width:
                                      MediaQuery.of(context).size.width * 0.40,
                                  height:
                                      MediaQuery.of(context).size.height * 0.75,
                                  child: AppointmentDetailsContent(
                                    appointmentId: appModel.id,
                                    onAppointmentUpdated: () {
                                      // Esta función se llama cuando la cita se actualiza
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      _loadAppointments().then((_) {
                                        // Opcional: Mostrar mensaje de confirmación
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Cita actualizada correctamente'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ).then((result) {
                                  // Si result es true, significa que se cerró después de una actualización
                                  if (result == true) {
                                    _loadAppointments();
                                  }
                                });
                              }
                            } else if (details.targetElement ==
                                CalendarElement.calendarCell) {
                              // Código existente para crear nueva cita al hacer clic en una celda
                              _removeCurrentTooltip();
                              final tappedDateTime = details.date;
                              if (tappedDateTime != null) {
                                print(
                                    'Seleccionando fecha en calendario: ${tappedDateTime.toString()}');
                                print(
                                    'Hora seleccionada: ${tappedDateTime.hour}:${tappedDateTime.minute}');

                                // Asegúrate de que la fecha/hora es exacta
                                final exactDateTime = DateTime(
                                  tappedDateTime.year,
                                  tappedDateTime.month,
                                  tappedDateTime.day,
                                  tappedDateTime.hour,
                                  tappedDateTime.minute,
                                );

                                // Mostrar el diálogo en lugar de navegar
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AppointmentDialog(
                                      initialDate: exactDateTime,
                                      initialStartTime: TimeOfDay(
                                        hour: exactDateTime.hour,
                                        minute: exactDateTime.minute,
                                      ),
                                    );
                                  },
                                ).then((result) {
                                  // Si se creó una cita correctamente, recarga las citas
                                  if (result != null) {
                                    if (result is Map<String, dynamic> &&
                                        result.containsKey('date')) {
                                      // Si el diálogo nos devuelve la fecha, pero no necesitamos actualizar la seleccionada
                                      // porque ya estamos en esa vista del calendario
                                    }
                                    _loadAppointments();
                                  }
                                });
                              }
                            }
                          },

                          // Cambio de vista, fechas seleccionadas, etc.
                          onViewChanged: (ViewChangedDetails details) {
                            if (details.visibleDates.isNotEmpty) {
                              // Obtener la fecha central del rango visible
                              final midDate = details.visibleDates[
                                  details.visibleDates.length ~/ 2];

                              // Determinar si necesitamos actualizar la fecha seleccionada y recargar citas
                              bool needsUpdate = false;

                              // Para vista diaria o semanal, verificamos si estamos en un día diferente
                              if (_viewType == 0 || _viewType == 1) {
                                // Semana o Día
                                // Obtener el primer día de la semana actual seleccionada
                                final currentWeekStart = DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month,
                                  _selectedDate.day -
                                      (_selectedDate.weekday - 1),
                                );

                                // Obtener el primer día de la nueva semana visible
                                final newWeekStart = DateTime(
                                  midDate.year,
                                  midDate.month,
                                  midDate.day - (midDate.weekday - 1),
                                );

                                // Si cambiamos de semana, necesitamos actualizar
                                if (!_isSameDay(
                                    currentWeekStart, newWeekStart)) {
                                  needsUpdate = true;
                                }
                              }
                              // Para vista mensual, verificamos si estamos en un mes diferente
                              else if (_viewType == 2) {
                                // Mes
                                if (_selectedDate.month != midDate.month ||
                                    _selectedDate.year != midDate.year) {
                                  needsUpdate = true;
                                }
                              }

                              // Si necesitamos actualizar, establecemos la nueva fecha seleccionada y recargamos
                              if (needsUpdate) {
                                print(
                                    'Cambio de vista detectado: ${_selectedDate} -> ${midDate}');
                                setState(() {
                                  _selectedDate = midDate;
                                });
                                _loadAppointments();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showTherapistFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Terapeuta'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _therapists.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('Todos los Terapeutas'),
                  selected: _selectedTherapistId == null,
                  onTap: () {
                    Navigator.pop(context);
                    _filterByTherapist(null);
                  },
                );
              } else {
                final therapist = _therapists[index - 1];
                return ListTile(
                  title: Text(therapist.fullName),
                  selected: _selectedTherapistId == therapist.id,
                  onTap: () {
                    Navigator.pop(context);
                    _filterByTherapist(therapist.id);
                  },
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

// Clase para manejar los datos de citas para SfCalendar
class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
