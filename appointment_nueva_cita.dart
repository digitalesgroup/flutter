// lib/screens/appointment_nueva_cita.dart

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

// Appointment Add Screen
class AppointmentAddScreen extends StatefulWidget {
  final String? clientId;
  final DateTime? initialDate;
  final bool fromCalendar;

  const AppointmentAddScreen({
    this.clientId,
    this.initialDate,
    this.fromCalendar = false,
  });

  @override
  _AppointmentAddScreenState createState() => _AppointmentAddScreenState();
}

class _AppointmentAddScreenState extends State<AppointmentAddScreen> {
  final _formKey = GlobalKey<FormState>();

  // Para el buscador de clientes
  final TextEditingController _clientSearchController = TextEditingController();

  // Selected client
  UserModel? _selectedClient;
  List<UserModel> _clients = [];
  bool _isClientLoading = false;

  // Selected therapist
  UserModel? _selectedTherapist;
  List<UserModel> _therapists = [];
  bool _isTherapistLoading = false;

  // Date and time
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: (TimeOfDay.now().hour + 1) % 24,
  );

  // Treatment info
  final _reasonController = TextEditingController();
  String _treatmentType = 'Masajes';
  final _notesController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

  // Controladores para fecha y hora
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;

      print(
          'AppointmentAddScreen - didChangeDependencies INICIO - _initialized: $_initialized');

      // Inicializa los controladores con los valores predeterminados
      _dateController.text =
          DateFormat('EEEE, d MMMM, yyyy', 'es').format(_selectedDate);
      _startTimeController.text = _startTime.format(context);
      _endTimeController.text = _endTime.format(context);

      // Usa los props directamente en lugar de args
      if (widget.initialDate != null) {
        print(
            'AppointmentAddScreen - Usando initialDate del constructor: ${widget.initialDate}');
        print('AppointmentAddScreen - fromCalendar: ${widget.fromCalendar}');

        final DateTime initialDate = widget.initialDate!;

        // Establece la fecha seleccionada
        _selectedDate =
            DateTime(initialDate.year, initialDate.month, initialDate.day);

        // Si viene desde la vista de calendario, usa la hora exacta
        if (widget.fromCalendar) {
          _startTime =
              TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);

          // Calcula la hora de finalización (1 hora después)
          final int totalMinutes =
              initialDate.hour * 60 + initialDate.minute + 60;
          final int endHour = (totalMinutes ~/ 60) % 24;
          final int endMinute = totalMinutes % 60;
          _endTime = TimeOfDay(hour: endHour, minute: endMinute);

          print(
              'AppointmentAddScreen - Hora configurada: ${_startTime.hour}:${_startTime.minute}');
        }

        // Actualiza los controladores de texto con los nuevos valores
        _dateController.text =
            DateFormat('EEEE, d MMMM, yyyy', 'es').format(_selectedDate);
        _startTimeController.text = _startTime.format(context);
        _endTimeController.text = _endTime.format(context);
      }

      // Carga los datos iniciales
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _clientSearchController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isClientLoading = true;
      _isTherapistLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Carga clientes y terapeutas
      final clients = await dbService.getClients();
      final therapists = await dbService.getTherapists();

      setState(() {
        _clients = clients;
        _therapists = therapists;
        _isClientLoading = false;
        _isTherapistLoading = false;
      });

      // Si se proporcionó un clientId, selecciónalo
      if (widget.clientId != null) {
        final client = clients.firstWhere(
          (c) => c.id == widget.clientId,
          orElse: () => UserModel(
            id: '',
            name: '',
            lastName: '',
            role: UserRole.client,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        if (client.id.isNotEmpty) {
          setState(() {
            _selectedClient = client;
            _clientSearchController.text = client.fullName;
          });
        }
      }

      // Selecciona el primer terapeuta si hay alguno
      if (therapists.isNotEmpty) {
        setState(() {
          _selectedTherapist = therapists.first;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isClientLoading = false;
        _isTherapistLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', ''),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat('EEEE, d MMMM, yyyy', 'es').format(_selectedDate);
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        _startTimeController.text = _startTime.format(context);

        // Ajusta _endTime si es necesario (mínimo 1 hora después)
        final int startTotalMinutes = picked.hour * 60 + picked.minute;
        final int endTotalMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endTotalMinutes <= startTotalMinutes) {
          _endTime = TimeOfDay(
            hour: (startTotalMinutes + 60) ~/ 60 % 24,
            minute: (startTotalMinutes + 60) % 60,
          );
          _endTimeController.text = _endTime.format(context);
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      final int startTotalMinutes = _startTime.hour * 60 + _startTime.minute;
      final int pickedTotalMinutes = picked.hour * 60 + picked.minute;
      if (pickedTotalMinutes <= startTotalMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('La hora de fin debe ser después de la hora de inicio'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        setState(() {
          _endTime = picked;
          _endTimeController.text = _endTime.format(context);
        });
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedClient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un cliente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedTherapist == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un terapeuta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _isSaving = true;
      });
      try {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final notificationService =
            Provider.of<NotificationService>(context, listen: false);

        final appointmentModel = AppointmentModel(
          id: '', // Se asignará al guardarlo en Firebase
          clientId: _selectedClient!.id,
          employeeId: _selectedTherapist!.id,
          date: _selectedDate,
          startTime: _startTime,
          endTime: _endTime,
          status: AppointmentStatus.scheduled,
          reason: _reasonController.text.trim(),
          treatmentType: _treatmentType,
          notes: _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Guarda la cita en la base de datos
        final appointmentId = await dbService.addAppointment(appointmentModel);

        // Intentar programar la notificación, pero no fallar si hay error
        try {
          await notificationService.scheduleAppointmentReminder(
            appointmentModel.copyWith(id: appointmentId),
          );
        } catch (notificationError) {
          print(
              'Advertencia: No se pudo programar la notificación: $notificationError');
          // No mostramos error al usuario ya que la cita se guardó correctamente
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita programada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error saving appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cita: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Selección de Cliente (TypeAhead) ---

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isClientLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TypeAheadFormField<UserModel>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _clientSearchController,
                                decoration: const InputDecoration(
                                  labelText: 'Buscar cliente',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
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
                                  _selectedClient = suggestion;
                                  _clientSearchController.text =
                                      suggestion.fullName;
                                });
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
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 8),
                            if (_selectedClient != null)
                              Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cliente seleccionado: ${_selectedClient!.fullName}',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _selectedClient = null;
                                        _clientSearchController.clear();
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Selección de Terapeuta (Dropdown) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isTherapistLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Terapeuta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedTherapist?.id,
                              hint: const Text('Seleccione un terapeuta'),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              items: _therapists.map((therapist) {
                                return DropdownMenuItem<String>(
                                  value: therapist.id,
                                  child: Text(therapist.fullName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTherapist = _therapists
                                        .firstWhere((t) => t.id == value);
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor seleccione un terapeuta';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Fecha y Hora ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha y Hora',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            controller: _dateController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor seleccione una fecha';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectStartTime(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Hora Inicio',
                                    prefixIcon: Icon(Icons.access_time),
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: _startTimeController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Seleccione hora';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectEndTime(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Hora Fin',
                                    prefixIcon: Icon(Icons.access_time),
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: _endTimeController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Seleccione hora';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Información del Tratamiento ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Tratamiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _treatmentType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Tratamiento',
                          prefixIcon: Icon(Icons.spa),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Masajes',
                            child: Text('Masajes'),
                          ),
                          DropdownMenuItem(
                            value: 'Tratamiento Facial',
                            child: Text('Tratamiento Facial'),
                          ),
                          DropdownMenuItem(
                            value: 'Tratamiento Corporal',
                            child: Text('Tratamiento Corporal'),
                          ),
                          DropdownMenuItem(
                            value: 'Post Operatorio',
                            child: Text('Post Operatorio'),
                          ),
                          DropdownMenuItem(
                            value: 'Camara de Bronceado',
                            child: Text('Camara de Bronceado'),
                          ),
                          DropdownMenuItem(
                            value: 'Depilacion',
                            child: Text('Depilacion'),
                          ),
                          DropdownMenuItem(
                            value: 'Botox',
                            child: Text('Botox'),
                          ),
                          DropdownMenuItem(
                            value: 'Otros',
                            child: Text('Otros'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _treatmentType = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione un tipo de tratamiento';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Motivo',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el motivo de la cita';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón de guardar
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Programar Cita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
