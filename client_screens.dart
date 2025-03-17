// lib/screens/client_screens.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../routes.dart';
import '../widgets/client_widgets.dart';
import '../app_theme.dart';
import '../widgets/responsive_layout.dart';
import 'package:spa_meu/screens/client_add_screen.dart';
import '../models/navigation_state.dart';

// -----------------------------
// 1) LISTA DE CLIENTES
// -----------------------------
class ClientListScreen extends StatefulWidget {
  // Agregamos el callback como parámetro opcional
  final Function(String)? onClientSelected;

  ClientListScreen({Key? key, this.onClientSelected}) : super(key: key);

  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<UserModel> _clients = [];
  List<UserModel> _filteredClients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadClients();
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadClients() async {
    if (!mounted) return;

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final clients = await dbService.getClients();

      if (!mounted) return;

      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clients: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _filterClients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          final name = client.name.toLowerCase();
          final lastName = client.lastName.toLowerCase();
          final fullName = '${client.name} ${client.lastName}'.toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              lastName.contains(searchLower) ||
              fullName.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);
    final double screenPadding = isMobile ? 8.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        // No incluir flecha de retroceso en la navegación principal
        automaticallyImplyLeading: widget.onClientSelected != null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.clientAdd);
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar cliente',
      ),
      body: Column(
        children: [
          // Barra de búsqueda rediseñada
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: screenPadding),
            child: TextField(
              onChanged: _filterClients,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterClients('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Lista de clientes rediseñada
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: isMobile ? 48 : 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron clientes',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () => _filterClients(''),
                                child: const Text('Mostrar todos los clientes'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: screenPadding),
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return _buildClientListItem(client);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Mantenemos el método original para la lista de clientes
  Widget _buildClientListItem(UserModel client) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 8.0 : 16.0;
    final double avatarSize = isMobile ? 40.0 : 50.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Si se proporcionó un callback, lo usamos
          if (widget.onClientSelected != null) {
            widget.onClientSelected!(client.id);
          } else {
            // Navegación estándar como fallback
            Navigator.of(context).pushNamed(
              AppRoutes.clientDetails,
              arguments: {'clientId': client.id},
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClientAvatar(
                photoUrl: client.photoUrl,
                size: avatarSize,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: isMobile ? 12 : 14,
                          color: AppTheme.lightTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          client.phone ?? 'Sin teléfono',
                          style: AppTheme.subtitleStyle.copyWith(
                            fontSize: isMobile ? 11 : 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.navigate_next,
                color: Colors.grey.shade400,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------
// 2) DETALLES DE CLIENTE
// -----------------------------
class ClientDetailsScreen extends StatefulWidget {
  final String? clientId;
  // Añadimos el parámetro onEditSelected
  final Function(String)? onEditSelected;

  const ClientDetailsScreen({this.clientId, this.onEditSelected});

  @override
  _ClientDetailsScreenState createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _client;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    if (widget.clientId == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final client = await dbService.getUser(widget.clientId!);

      setState(() {
        _client = client;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading client: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar cliente: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          text: _client?.fullName ?? 'Detalles del Cliente',
          mobileFontSize: 16,
          tabletFontSize: 18,
          desktopFontSize: 20,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              // Intentar usar la navegación anidada si está disponible
              Provider.of<NavigationState>(context, listen: false).goBack();
            } catch (e) {
              // Si no está disponible, usar navegación normal
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (_client != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Si se proporcionó un callback, lo usamos
                if (widget.onEditSelected != null) {
                  widget.onEditSelected!(_client!.id);
                } else {
                  // Navegación estándar como fallback
                  Navigator.of(context).pushNamed(
                    AppRoutes.clientEdit,
                    arguments: {'clientId': _client!.id},
                  );
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          labelColor: Colors.white, // Color del texto del tab seleccionado
          unselectedLabelColor:
              Colors.white, // Color del texto de los tabs no seleccionados
          indicatorColor: Colors
              .white, // Opcional: Color de la línea indicadora debajo del tab seleccionado
          tabs: [
            Tab(
              text: 'Información',
            ),
            Tab(
              text: 'Citas',
            ),
            Tab(
              text: 'Pagos',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _client == null
              ? const Center(child: Text('Cliente no encontrado'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Info Tab - Responsivo
                    SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 0 : 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client Avatar - centrado y responsivo
                          //Center(
                          // child: ClientAvatar(
                          //  photoUrl: _client!.photoUrl,
                          // size: isMobile ? 100 : 120,
                          //  ),
                          //),
                          //SizedBox(height: isMobile ? 16 : 24),

                          // Client Info Card - adaptado al ancho
                          ClientInfoCard(client: _client!),

                          SizedBox(height: isMobile ? 12 : 16),
                        ],
                      ),
                    ),

                    // Appointments Tab
                    ClientAppointmentsTab(clientId: _client!.id),

                    // Payments Tab
                    ClientPaymentsTab(clientId: _client!.id),
                  ],
                ),
      floatingActionButton: _client != null && _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.appointmentAdd,
                  arguments: {'clientId': _client!.id},
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// -----------------------------
// 4) EDITAR CLIENTE
// -----------------------------
class ClientEditScreen extends StatefulWidget {
  final String? clientId;

  const ClientEditScreen({this.clientId});

  @override
  _ClientEditScreenState createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends State<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  String? _photoUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _client;

  // Nuevos controladores y variables para historial médico y estético
  bool _tieneDiabetes = false;
  bool _tieneAsma = false;
  bool _tieneHipertension = false;
  bool _tieneCancer = false;
  final _alergiasController = TextEditingController();
  bool _tieneOtrasCondicionesMedicas = false;
  final _otrasCondicionesMedicasController = TextEditingController();

  bool _tieneProcedimientosEsteticosPrevios = false;
  final _procedimientosEsteticosPreviosController = TextEditingController();
  bool _tieneCirugias = false;
  final _cirugiasController = TextEditingController();
  bool _tieneImplantes = false;
  final _implantesController = TextEditingController();
  final _tratamientosActualesController = TextEditingController();
  final _preferenciasTratamientoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medicalNotesController.dispose();
    _alergiasController.dispose();
    _otrasCondicionesMedicasController.dispose();
    _procedimientosEsteticosPreviosController.dispose();
    _cirugiasController.dispose();
    _implantesController.dispose();
    _tratamientosActualesController.dispose();
    _preferenciasTratamientoController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    if (widget.clientId == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final client = await dbService.getUser(widget.clientId!);

      // Set form values
      _nameController.text = client.name;
      _lastNameController.text = client.lastName;
      _emailController.text = client.email ?? '';
      _phoneController.text = client.phone ?? '';
      _addressController.text = client.address ?? '';
      _medicalNotesController.text = client.medicalNotes ?? '';
      _birthDate = client.birthDate;
      _gender = client.gender;
      _photoUrl = client.photoUrl;

      // Nuevos campos
      _tieneDiabetes = client.tieneDiabetes ?? false;
      _tieneAsma = client.tieneAsma ?? false;
      _tieneHipertension = client.tieneHipertension ?? false;
      _tieneCancer = client.tieneCancer ?? false;
      _alergiasController.text = client.alergias ?? '';
      _tieneOtrasCondicionesMedicas = client.tieneOtrasCondiciones ?? false;
      _otrasCondicionesMedicasController.text = client.otrasCondiciones ?? '';

      _tieneProcedimientosEsteticosPrevios =
          client.tieneProcedimientosEsteticosPrevios ?? false;
      _procedimientosEsteticosPreviosController.text =
          client.procedimientosEsteticosPrevios ?? '';
      _tieneCirugias = client.tieneCirugias ?? false;
      _cirugiasController.text = client.cirugias ?? '';
      _tieneImplantes = client.tieneImplantes ?? false;
      _implantesController.text = client.implantes ?? '';
      _tratamientosActualesController.text = client.tratamientosActuales ?? '';
      _preferenciasTratamientoController.text =
          client.preferenciasTratamiento ?? '';

      setState(() {
        _client = client;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading client: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar cliente: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _updateClient() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final storageService =
            Provider.of<StorageService>(context, listen: false);

        // Update photo URL if new image is selected
        String? updatedPhotoUrl = _photoUrl;
        if (_imageFile != null) {
          updatedPhotoUrl = await storageService.uploadClientImage(
            widget.clientId!,
            _imageFile!,
          );
        }

        // Create updated user model
        final updatedClient = _client!.copyWith(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
          photoUrl: updatedPhotoUrl,
          medicalNotes: _medicalNotesController.text.trim(),
          updatedAt: DateTime.now(),
          // Nuevos campos actualizados
          tieneDiabetes: _tieneDiabetes,
          tieneAsma: _tieneAsma,
          tieneHipertension: _tieneHipertension,
          tieneCancer: _tieneCancer,
          alergias: _alergiasController.text.trim(),
          tieneOtrasCondiciones: _tieneOtrasCondicionesMedicas,
          otrasCondiciones: _otrasCondicionesMedicasController.text.trim(),
          tieneProcedimientosEsteticosPrevios:
              _tieneProcedimientosEsteticosPrevios,
          procedimientosEsteticosPrevios:
              _procedimientosEsteticosPreviosController.text.trim(),
          tieneCirugias: _tieneCirugias,
          cirugias: _cirugiasController.text.trim(),
          tieneImplantes: _tieneImplantes,
          implantes: _implantesController.text.trim(),
          tratamientosActuales: _tratamientosActualesController.text.trim(),
          preferenciasTratamiento:
              _preferenciasTratamientoController.text.trim(),
        );

        // Update client in database
        await dbService.updateUser(updatedClient);

        // Navigate back
        if (mounted) {
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error updating client: $e');

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar cliente: ${e.toString()}'),
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
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);
    final double sidePadding = isMobile ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          text: 'Editar Cliente',
          mobileFontSize: 16,
          tabletFontSize: 18,
          desktopFontSize: 20,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              // Intenta usar la navegación anidada
              Provider.of<NavigationState>(context, listen: false)
                  .navigateToDetail('client', widget.clientId ?? '');
            } catch (e) {
              // Si falla, usa la navegación estándar
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(sidePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: isMobile ? 50 : 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_photoUrl != null
                                  ? NetworkImage(_photoUrl!) as ImageProvider
                                  : null),
                          child: (_imageFile == null && _photoUrl == null)
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: isMobile ? 30 : 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 24),

                    // Secciones responsivas para la edición de cliente
                    _buildResponsiveEditSections(),

                    SizedBox(height: isMobile ? 24 : 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _updateClient,
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Guardar Cambios',
                              style: TextStyle(fontSize: isMobile ? 14 : 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget para organizar las secciones de edición de manera responsiva
  Widget _buildResponsiveEditSections() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);

    // Para pantallas móviles, apilamos todo verticalmente
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Información Básica
          _buildSectionTitle('Información Básica'),
          SizedBox(height: 12),
          _buildResponsiveTextFields(),
          SizedBox(height: 24),

          // Información de Contacto
          _buildSectionTitle('Información de Contacto'),
          SizedBox(height: 12),
          _buildResponsiveContactFields(),
          SizedBox(height: 24),

          // Historial Médico
          _buildResponsiveMedicalHistory(),
          SizedBox(height: 16),

          // Historial Estético
          _buildResponsiveAestheticHistory(),
          SizedBox(height: 24),

          // Notas Adicionales
          _buildSectionTitle('Notas Adicionales'),
          SizedBox(height: 12),
          TextFormField(
            controller: _medicalNotesController,
            decoration: InputDecoration(
              labelText: 'Observaciones Médicas o Preferencias',
              hintText: 'Otras notas médicas, preferencias, etc.',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
        ],
      );
    } else {
      // Para tablet/desktop, usamos un diseño más horizontal donde sea posible
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Información Básica
          _buildSectionTitle('Información Básica'),
          SizedBox(height: 16),
          _buildResponsiveTextFields(),
          SizedBox(height: 24),

          // Información de Contacto
          _buildSectionTitle('Información de Contacto'),
          SizedBox(height: 16),
          _buildResponsiveContactFields(),
          SizedBox(height: 24),

          // Secciones de historial en diseño de dos columnas para desktop
          if (ResponsiveBreakpoints.isDesktop(context))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildResponsiveMedicalHistory()),
                SizedBox(width: 16),
                Expanded(child: _buildResponsiveAestheticHistory()),
              ],
            )
          else
            Column(
              children: [
                _buildResponsiveMedicalHistory(),
                SizedBox(height: 16),
                _buildResponsiveAestheticHistory(),
              ],
            ),
          SizedBox(height: 24),

          // Notas Adicionales
          _buildSectionTitle('Notas Adicionales'),
          SizedBox(height: 16),
          TextFormField(
            controller: _medicalNotesController,
            decoration: const InputDecoration(
              labelText: 'Observaciones Médicas o Preferencias Adicionales',
              hintText: 'Otras notas médicas, preferencias, etc.',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      );
    }
  }

  // Widget para los campos de texto básicos responsivos
  Widget _buildResponsiveTextFields() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el nombre';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Apellido',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el apellido';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          _buildDateField(context),
          SizedBox(height: 12),
          _buildGenderDropdown(),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el apellido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateField(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildGenderDropdown()),
            ],
          ),
        ],
      );
    }
  }

  // Widget para los campos de contacto responsivos
  Widget _buildResponsiveContactFields() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el teléfono';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.home),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el teléfono';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      );
    }
  }

  // Widget para el historial médico responsivo
  Widget _buildResponsiveMedicalHistory() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial Médico',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Checkboxes responsivos
            Wrap(
              spacing: isMobile ? 0 : 16,
              runSpacing: 0,
              children: [
                _buildResponsiveSwitch('Diabetes:', _tieneDiabetes, (value) {
                  setState(() {
                    _tieneDiabetes = value;
                  });
                }),
                _buildResponsiveSwitch('Asma:', _tieneAsma, (value) {
                  setState(() {
                    _tieneAsma = value;
                  });
                }),
              ],
            ),
            Wrap(
              spacing: isMobile ? 0 : 16,
              runSpacing: 0,
              children: [
                _buildResponsiveSwitch('Hipertensión:', _tieneHipertension,
                    (value) {
                  setState(() {
                    _tieneHipertension = value;
                  });
                }),
                _buildResponsiveSwitch('Cáncer:', _tieneCancer, (value) {
                  setState(() {
                    _tieneCancer = value;
                  });
                }),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _alergiasController,
              decoration: InputDecoration(
                labelText: 'Alergias (opcional)',
                hintText: 'Especificar alergias',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            _buildResponsiveSwitch(
                'Otras Condiciones Médicas:', _tieneOtrasCondicionesMedicas,
                (value) {
              setState(() {
                _tieneOtrasCondicionesMedicas = value;
              });
            }),
            if (_tieneOtrasCondicionesMedicas)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _otrasCondicionesMedicasController,
                  decoration: InputDecoration(
                    labelText: 'Especificar Otras Condiciones Médicas',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget para el historial estético responsivo
  Widget _buildResponsiveAestheticHistory() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial Estético',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Checkboxes responsivos para historial estético
            _buildResponsiveSwitch('Procedimientos Estéticos Previos:',
                _tieneProcedimientosEsteticosPrevios, (value) {
              setState(() {
                _tieneProcedimientosEsteticosPrevios = value;
              });
            }),
            if (_tieneProcedimientosEsteticosPrevios)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _procedimientosEsteticosPreviosController,
                  decoration: InputDecoration(
                    labelText:
                        'Especificar Procedimientos Estéticos Previos (opcional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                  ),
                  maxLines: 2,
                ),
              ),
            SizedBox(height: isMobile ? 8 : 12),
            _buildResponsiveSwitch('Cirugías:', _tieneCirugias, (value) {
              setState(() {
                _tieneCirugias = value;
              });
            }),
            if (_tieneCirugias)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _cirugiasController,
                  decoration: InputDecoration(
                    labelText: 'Especificar Cirugías (opcional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                  ),
                  maxLines: 2,
                ),
              ),
            SizedBox(height: isMobile ? 8 : 12),
            _buildResponsiveSwitch('Implantes:', _tieneImplantes, (value) {
              setState(() {
                _tieneImplantes = value;
              });
            }),
            if (_tieneImplantes)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _implantesController,
                  decoration: InputDecoration(
                    labelText: 'Especificar Implantes (opcional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                  ),
                  maxLines: 2,
                ),
              ),
            SizedBox(height: 16),
            TextFormField(
              controller: _tratamientosActualesController,
              decoration: InputDecoration(
                labelText: 'Tratamientos Estéticos Actuales (opcional)',
                hintText:
                    'Tratamientos estéticos que esté recibiendo actualmente',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _preferenciasTratamientoController,
              decoration: InputDecoration(
                labelText: 'Preferencias de Tratamiento (opcional)',
                hintText: 'Preferencias generales de tratamiento',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para switches responsivos
  Widget _buildResponsiveSwitch(
      String label, bool value, Function(bool) onChanged) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  // Widget para título de sección
  Widget _buildSectionTitle(String title) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Text(
      title,
      style: TextStyle(
        fontSize: isMobile ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  // Widget para seleccionar fecha
  Widget _buildDateField(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento',
            suffixIcon:
                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16, vertical: isMobile ? 12 : 16),
          ),
          controller: TextEditingController(
            text: _birthDate != null
                ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                : '',
          ),
        ),
      ),
    );
  }

  // Widget para dropdown de género
  Widget _buildGenderDropdown() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Género',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 12 : 16),
      ),
      items: const [
        DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
        DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
      ],
      onChanged: (value) {
        setState(() {
          _gender = value;
        });
      },
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }
}

// -----------------------------
// 5) PESTAÑA DE PAGOS POR CLIENTE
// -----------------------------

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
      // Solo transacciones del cliente actual
      final transactions =
          await dbService.getClientTransactions(widget.clientId);

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar transacciones: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: isMobile ? 48 : 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No hay transacciones para este cliente',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: AppTheme.lightTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (_, index) {
          final t = _transactions[index];
          return Card(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: 4,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: t.type == TransactionType.payment
                    ? Colors.green
                    : Colors.red,
                radius: isMobile ? 18 : 22,
                child: Icon(
                  t.type == TransactionType.payment
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: Colors.white,
                  size: isMobile ? 16 : 20,
                ),
              ),
              // "Pago de cliente" vs "Deuda de cliente"
              title: Text(
                t.type == TransactionType.payment
                    ? 'Pago de cliente'
                    : 'Deuda de cliente',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(t.date) +
                    ' - ${_getPaymentMethodName(t.method)}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              trailing: Text(
                '\$${t.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: t.type == TransactionType.payment
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              onTap: () => _showTransactionDetails(t),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markTransactionAsPaid(TransactionModel transaction) async {
    final updatedTransaction = transaction.copyWith(
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      updatedAt: DateTime.now(),
    );

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.updateTransaction(updatedTransaction);

      // Cierra el diálogo
      Navigator.of(context).pop();

      // Recarga la lista
      await _loadTransactions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Transacción marcada como pagada!'),
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

  void _showTransactionDetails(TransactionModel transaction) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Detalles de Transacción',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                  'Tipo',
                  transaction.type == TransactionType.payment
                      ? 'Pago'
                      : 'Pendiente de cobro'),
              _buildDetailItem(
                  'Monto', '\$${transaction.amount.toStringAsFixed(2)}'),
              _buildDetailItem(
                  'Método de Pago', _getPaymentMethodName(transaction.method)),
              _buildDetailItem(
                  'Estado',
                  transaction.status == TransactionStatus.completed
                      ? 'Completado'
                      : 'Pendiente'),
              _buildDetailItem('Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailItem('Notas', transaction.notes!),
            ],
          ),
        ),
        actions: [
          // Solo si es deuda
          if (transaction.type == TransactionType.debt)
            TextButton(
              onPressed: () => _markTransactionAsPaid(transaction),
              child: Text(
                'Marcar como pagada',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 8 : 16,
        ),
      ),
    );
  }

  // Widget para mostrar un elemento de detalle
  Widget _buildDetailItem(String title, String value) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          Divider(),
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
}
