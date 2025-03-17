// lib/widgets/appointment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../app_theme.dart';

class AppointmentDialog extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay initialStartTime;
  final String? preSelectedClientId;

  const AppointmentDialog({
    Key? key,
    required this.initialDate,
    required this.initialStartTime,
    this.preSelectedClientId,
  }) : super(key: key);

  @override
  _AppointmentDialogState createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientSearchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  UserModel? _selectedClient;
  UserModel? _selectedTherapist;
  List<UserModel> _clients = [];
  List<UserModel> _therapists = [];

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime =
      TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);

  String _treatmentType = 'Masajes';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = widget.initialStartTime;

    // Calcula el tiempo de finalización (1 hora después)
    final int totalMinutes = _startTime.hour * 60 + _startTime.minute + 60;
    final int endHour = (totalMinutes ~/ 60) % 24;
    final int endMinute = totalMinutes % 60;
    _endTime = TimeOfDay(hour: endHour, minute: endMinute);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Cargar clientes y terapeutas
      final clients = await dbService.getClients();
      final therapists = await dbService.getTherapists();

      setState(() {
        _clients = clients;
        _therapists = therapists;
        _isLoading = false;
      });

      // Si hay un cliente preseleccionado
      if (widget.preSelectedClientId != null) {
        final client = clients.firstWhere(
          (c) => c.id == widget.preSelectedClientId,
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

      // Seleccionar terapeuta por defecto
      if (therapists.isNotEmpty) {
        setState(() => _selectedTherapist = therapists.first);
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

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

    setState(() => _isSaving = true);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);

      final appointmentModel = AppointmentModel(
        id: '',
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

      // Guardar cita
      final appointmentId = await dbService.addAppointment(appointmentModel);

      // Programar notificación
      try {
        await notificationService.scheduleAppointmentReminder(
          appointmentModel.copyWith(id: appointmentId),
        );
      } catch (notificationError) {
        print(
            'Advertencia: No se pudo programar la notificación: $notificationError');
      }

      if (mounted) {
        // En lugar de devolver solo true, devolvemos un mapa con información útil
        Navigator.of(context).pop({
          'success': true,
          'date': _selectedDate,
          'appointmentId': appointmentId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita programada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error guardando cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar cita: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Programar Nueva Cita',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenido principal con scroll
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Fecha y hora
                            _buildDateTimeSection(),
                            const SizedBox(height: 16),

                            // Selección de cliente
                            _buildClientSection(),
                            const SizedBox(height: 16),

                            // Selección de terapeuta
                            _buildTherapistSection(),
                            const SizedBox(height: 16),

                            // Información del tratamiento
                            _buildTreatmentSection(),
                          ],
                        ),
                      ),
                    ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
                        : const Text('Guardar Cita'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha y Hora',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modificar esta parte para hacerla clickeable
              GestureDetector(
                onTap: () async {
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
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, d MMMM, yyyy', 'es')
                          .format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null && picked != _startTime) {
                          setState(() {
                            _startTime = picked;

                            // Ajustar hora de fin si es necesario
                            final startMinutes =
                                picked.hour * 60 + picked.minute;
                            final endMinutes =
                                _endTime.hour * 60 + _endTime.minute;

                            if (endMinutes <= startMinutes) {
                              _endTime = TimeOfDay(
                                hour: (startMinutes + 60) ~/ 60 % 24,
                                minute: (startMinutes + 60) % 60,
                              );
                            }
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora de inicio',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (picked != null && picked != _endTime) {
                          final startMinutes =
                              _startTime.hour * 60 + _startTime.minute;
                          final pickedMinutes =
                              picked.hour * 60 + picked.minute;

                          if (pickedMinutes <= startMinutes) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'La hora de fin debe ser después de la hora de inicio'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            setState(() => _endTime = picked);
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora de fin',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TypeAheadFormField<UserModel>(
          textFieldConfiguration: TextFieldConfiguration(
            controller: _clientSearchController,
            decoration: InputDecoration(
              labelText: 'Buscar cliente',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          suggestionsCallback: (pattern) {
            final query = pattern.toLowerCase().trim();
            if (query.isEmpty) {
              return const Iterable<UserModel>.empty();
            }
            return _clients
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
            });
          },
          noItemsFoundBuilder: (context) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '¡No se encontraron resultados!',
                style: TextStyle(color: Colors.grey.shade600),
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
        if (_selectedClient != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cliente seleccionado: ${_selectedClient!.fullName}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _selectedClient = null;
                      _clientSearchController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTherapistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terapeuta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTherapist?.id,
          hint: const Text('Seleccione un terapeuta'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                _selectedTherapist =
                    _therapists.firstWhere((t) => t.id == value);
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
    );
  }

  Widget _buildTreatmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Tratamiento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _treatmentType,
          decoration: InputDecoration(
            labelText: 'Tipo de Tratamiento',
            prefixIcon: const Icon(Icons.spa),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Masajes', child: Text('Masajes')),
            DropdownMenuItem(
                value: 'Tratamiento Facial', child: Text('Tratamiento Facial')),
            DropdownMenuItem(
                value: 'Tratamiento Corporal',
                child: Text('Tratamiento Corporal')),
            DropdownMenuItem(
                value: 'Post Operatorio', child: Text('Post Operatorio')),
            DropdownMenuItem(
                value: 'Camara de Bronceado',
                child: Text('Camara de Bronceado')),
            DropdownMenuItem(value: 'Depilacion', child: Text('Depilacion')),
            DropdownMenuItem(value: 'Botox', child: Text('Botox')),
            DropdownMenuItem(value: 'Otros', child: Text('Otros')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _treatmentType = value);
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
          decoration: InputDecoration(
            labelText: 'Motivo',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
          decoration: InputDecoration(
            labelText: 'Notas Adicionales (opcional)',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
