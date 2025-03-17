//lib/screens/client_add_screen.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/facial_mark_model.dart'; // NUEVO
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/facial_diagram_widget.dart'; // NUEVO

// -----------------------------
// 3) NUEVO CLIENTE
// -----------------------------
class ClientAddScreen extends StatefulWidget {
  @override
  _ClientAddScreenState createState() => _ClientAddScreenState();
}

class _ClientAddScreenState extends State<ClientAddScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para información básica
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  // Controladores para motivo de consulta
  final _motivoConsultaController = TextEditingController();

  // Controladores para hábitos de vida
  final _alimentacionController = TextEditingController();
  final _suenoController = TextEditingController();
  final _actividadFisicaController = TextEditingController();
  final _consumoAguaController = TextEditingController();

  // Variables para información básica
  DateTime? _birthDate;
  String? _gender;
  File? _imageFile;
  bool _isLoading = false;

  // Variables para historial médico
  bool _tieneAlergias = false;
  final _alergiasController = TextEditingController();
  bool _tieneRespiratorias = false;
  bool _tieneAlteracionesNerviosas = false;
  bool _tieneDiabetes = false;
  bool _tieneRenales = false;
  bool _tieneDigestivos = false;
  bool _tieneCardiacos = false;
  bool _tieneTiroides = false;
  bool _tieneCirugiasPrevias = false;
  final _cirugiasPreviasController = TextEditingController();
  bool _tieneOtrasCondiciones = false;
  final _otrasCondicionesController = TextEditingController();

  // Variables para historial estético
  bool _tieneProductosUsados = false;
  final _productosUsadosController = TextEditingController();
  bool _tieneOtrosEsteticos = false;
  final _otrosEsteticosController = TextEditingController();
  final _tratamientosActualesController = TextEditingController();
  final _preferenciasTratamientoController = TextEditingController();

  // Variables para hábitos de vida
  bool _fumador = false;
  bool _consumeAlcohol = false;
  bool _actividadFisicaRegular = false;
  bool _problemasDelSueno = false;

  // Variables para ficha de tratamiento
  String? _tipoTratamiento; // Facial, Corporal o Bronceado

  // NUEVO: Lista de marcas faciales
  List<FacialMark> _facialMarks = [];

  // Controladores y variables para tratamiento Facial
  final _tipoPielController = TextEditingController();
  final _estadoPielController = TextEditingController();
  String? _gradoFlacidez; // Leve, Moderado, Severo

  // Controladores y variables para tratamiento Corporal
  final _abdomenAltoController = TextEditingController();
  final _abdomenBajoController = TextEditingController();
  final _cinturaController = TextEditingController();
  final _espaldaController = TextEditingController();
  final _brazoIzqController = TextEditingController();
  final _brazoDerechoController = TextEditingController();
  final _pesoActualController = TextEditingController();
  final _alturaController = TextEditingController();
  String? _imc; // Calculado
  String? _nivelObesidad; // Normal, Sobrepeso, etc.

  // Variables para patologías corporales
  bool _tieneCelulitis = false;
  String? _gradoCelulitis; // Grado I, II, III, IV
  final _lugarCelulitisController = TextEditingController();
  bool _tieneEstrias = false;
  final _colorEstriasController = TextEditingController();
  final _tiempoEstriasController = TextEditingController();

  // Variables para bronceado
  String? _escalaGlasgow;
  String? _escalaFitzpatrick;

  @override
  void dispose() {
    // Disposición de controladores básicos
    _nameController.dispose();
    _lastNameController.dispose();
    _cedulaController.dispose();
    _ocupacionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medicalNotesController.dispose();

    // Disposición de controladores de historial médico y estético
    _alergiasController.dispose();
    _cirugiasPreviasController.dispose();
    _otrasCondicionesController.dispose();
    _productosUsadosController.dispose();
    _otrosEsteticosController.dispose();
    _tratamientosActualesController.dispose();
    _preferenciasTratamientoController.dispose();

    // Disposición de controladores de motivo de consulta
    _motivoConsultaController.dispose();

    // Disposición de controladores de hábitos de vida
    _alimentacionController.dispose();
    _suenoController.dispose();
    _actividadFisicaController.dispose();
    _consumoAguaController.dispose();

    // Disposición de controladores de tratamiento facial
    _tipoPielController.dispose();
    _estadoPielController.dispose();

    // Disposición de controladores de tratamiento corporal
    _abdomenAltoController.dispose();
    _abdomenBajoController.dispose();
    _cinturaController.dispose();
    _espaldaController.dispose();
    _brazoIzqController.dispose();
    _brazoDerechoController.dispose();
    _pesoActualController.dispose();
    _alturaController.dispose();
    _lugarCelulitisController.dispose();
    _colorEstriasController.dispose();
    _tiempoEstriasController.dispose();

    super.dispose();
  }

  // Método para calcular IMC
  void _calcularIMC() {
    if (_pesoActualController.text.isNotEmpty &&
        _alturaController.text.isNotEmpty) {
      try {
        double peso = double.parse(_pesoActualController.text);
        double altura =
            double.parse(_alturaController.text) / 100; // Convertir cm a m
        double imc = peso / (altura * altura);

        setState(() {
          _imc = imc.toStringAsFixed(2);

          // Determinar nivel de obesidad
          if (imc < 18.5) {
            _nivelObesidad = "Bajo peso";
          } else if (imc >= 18.5 && imc < 25) {
            _nivelObesidad = "Peso normal";
          } else if (imc >= 25 && imc < 30) {
            _nivelObesidad = "Sobrepeso";
          } else if (imc >= 30 && imc < 35) {
            _nivelObesidad = "Obesidad grado I";
          } else if (imc >= 35 && imc < 40) {
            _nivelObesidad = "Obesidad grado II";
          } else {
            _nivelObesidad = "Obesidad grado III";
          }
        });
      } catch (e) {
        setState(() {
          _imc = "Error";
          _nivelObesidad = "Error";
        });
      }
    }
  }

  // NUEVO: Método para actualizar las marcas faciales
  void _updateFacialMarks(List<FacialMark> marks) {
    setState(() {
      _facialMarks = marks;
    });
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _addClient() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final storageService =
            Provider.of<StorageService>(context, listen: false);

        var userModel = UserModel(
          id: '',
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          cedula: _cedulaController.text.trim(),
          ocupacion: _ocupacionController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
          medicalNotes: _medicalNotesController.text.trim(),
          role: UserRole.client,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),

          // Historial médico
          tieneAlergias: _tieneAlergias,
          alergias: _tieneAlergias ? _alergiasController.text.trim() : '',
          tieneRespiratorias: _tieneRespiratorias,
          tieneAlteracionesNerviosas: _tieneAlteracionesNerviosas,
          tieneDiabetes: _tieneDiabetes,
          tieneRenales: _tieneRenales,
          tieneDigestivos: _tieneDigestivos,
          tieneCardiacos: _tieneCardiacos,
          tieneTiroides: _tieneTiroides,
          tieneCirugiasPrevias: _tieneCirugiasPrevias,
          cirugiasPrevias: _tieneCirugiasPrevias
              ? _cirugiasPreviasController.text.trim()
              : '',
          tieneOtrasCondiciones: _tieneOtrasCondiciones,
          otrasCondiciones: _tieneOtrasCondiciones
              ? _otrasCondicionesController.text.trim()
              : '',

          // Historial estético
          tieneProductosUsados: _tieneProductosUsados,
          productosUsados: _tieneProductosUsados
              ? _productosUsadosController.text.trim()
              : '',
          tieneOtrosEsteticos: _tieneOtrosEsteticos,
          otrosEsteticos:
              _tieneOtrosEsteticos ? _otrosEsteticosController.text.trim() : '',
          tratamientosActuales: _tratamientosActualesController.text.trim(),
          preferenciasTratamiento:
              _preferenciasTratamientoController.text.trim(),

          // Motivo de consulta
          motivoConsulta: _motivoConsultaController.text.trim(),

          // Hábitos de vida
          fumador: _fumador,
          consumeAlcohol: _consumeAlcohol,
          actividadFisicaRegular: _actividadFisicaRegular,
          problemasDelSueno: _problemasDelSueno,
          alimentacion: _alimentacionController.text.trim(),
          sueno: _suenoController.text.trim(),
          actividadFisica: _actividadFisicaController.text.trim(),
          consumoAgua: _consumoAguaController.text.trim(),

          // Ficha de tratamiento
          tipoTratamiento: _tipoTratamiento,
          facialMarks: _facialMarks.isNotEmpty ? _facialMarks : null, // NUEVO

          // Tratamiento facial
          tipoPiel: _tipoPielController.text.trim(),
          estadoPiel: _estadoPielController.text.trim(),
          gradoFlacidez: _gradoFlacidez,

          // Tratamiento corporal - medidas
          abdomenAlto: _abdomenAltoController.text.trim(),
          abdomenBajo: _abdomenBajoController.text.trim(),
          cintura: _cinturaController.text.trim(),
          espalda: _espaldaController.text.trim(),
          brazoIzq: _brazoIzqController.text.trim(),
          brazoDerecho: _brazoDerechoController.text.trim(),

          // Tratamiento corporal - antropología
          pesoActual: _pesoActualController.text.trim(),
          altura: _alturaController.text.trim(),
          imc: _imc,
          nivelObesidad: _nivelObesidad,

          // Tratamiento corporal - patologías
          tieneCelulitis: _tieneCelulitis,
          gradoCelulitis: _gradoCelulitis,
          lugarCelulitis:
              _tieneCelulitis ? _lugarCelulitisController.text.trim() : '',
          tieneEstrias: _tieneEstrias,
          colorEstrias:
              _tieneEstrias ? _colorEstriasController.text.trim() : '',
          tiempoEstrias:
              _tieneEstrias ? _tiempoEstriasController.text.trim() : '',

          // Tratamiento bronceado
          escalaGlasgow: _escalaGlasgow,
          escalaFitzpatrick: _escalaFitzpatrick,
        );

        String clientId = await dbService.addUser(userModel);

        if (_imageFile != null) {
          String photoUrl = await storageService.uploadClientImage(
            clientId,
            _imageFile!,
          );
          userModel = userModel.copyWith(photoUrl: photoUrl);
          await dbService.updateUser(userModel);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cliente agregado exitosamente'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error adding client: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar cliente: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);
    final double sidePadding = isMobile ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          text: 'Nuevo Cliente',
          style: AppTheme.subheadingStyle,
          mobileFontSize: 16,
          tabletFontSize: 18,
          desktopFontSize: 20,
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: isMobile ? 50 : 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: isMobile ? 30 : 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Información Básica
                _buildSectionTitle('Información Básica'),
                _buildResponsiveTextFieldPair(
                    _nameController, _lastNameController, 'Nombre', 'Apellido',
                    isRequired: true),
                SizedBox(height: isMobile ? 12 : 16),
                _buildResponsiveTextFieldPair(_cedulaController,
                    _ocupacionController, 'Cédula', 'Ocupación',
                    isRequired: true),
                SizedBox(height: isMobile ? 12 : 16),
                _buildResponsiveDateGenderRow(context),

                SizedBox(height: isMobile ? 16 : 24),
                _buildSectionTitle('Información de Contacto'),
                _buildResponsiveContactInfo(),
                SizedBox(height: isMobile ? 12 : 16),
                _buildTextField(
                    _addressController, 'Dirección', Icons.home, null,
                    maxLines: 2),

                SizedBox(height: isMobile ? 16 : 24),
                _buildResponsiveMedicalHistorySection(),

                SizedBox(height: isMobile ? 16 : 24),
                _buildResponsiveAestheticHistorySection(),

                SizedBox(height: isMobile ? 16 : 24),
                _buildHabitosVidaSection(),

                SizedBox(height: isMobile ? 16 : 24),
                _buildMotivoConsultaSection(),

                SizedBox(height: isMobile ? 16 : 24),
                _buildFichaTratamientoSection(),

                SizedBox(height: isMobile ? 20 : 24),
                _buildSectionTitle('Notas Adicionales'),
                _buildTextField(
                    _medicalNotesController, 'Observaciones', null, null,
                    maxLines: 3),

                SizedBox(height: isMobile ? 24 : 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTheme.subheadingStyle.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 16 : 18,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData? icon,
    TextInputType? keyboardType, {
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          prefixIcon:
              icon != null ? Icon(icon, color: AppTheme.primaryColor) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              vertical: isMobile ? 12 : 16, horizontal: isMobile ? 8 : 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor),
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) => value == null || value.isEmpty
                ? 'Este campo es requerido'
                : null
            : validator,
      ),
    );
  }

  // Widget para campos de texto responsivos (lado a lado o apilados)
  Widget _buildResponsiveTextFieldPair(TextEditingController controller1,
      TextEditingController controller2, String label1, String label2,
      {bool isRequired = false}) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    // En móvil, apilamos los campos verticalmente
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(controller1, label1, null, null,
              isRequired: isRequired),
          SizedBox(height: 12),
          _buildTextField(controller2, label2, null, null,
              isRequired: isRequired),
        ],
      );
    } else {
      // En tablet/desktop, mostramos en fila
      return Row(
        children: [
          Expanded(
              child: _buildTextField(controller1, label1, null, null,
                  isRequired: isRequired)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(controller2, label2, null, null,
                  isRequired: isRequired)),
        ],
      );
    }
  }

  // Widget responsivo para fecha y género
  Widget _buildResponsiveDateGenderRow(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildDateField(context),
          SizedBox(height: 12),
          _buildGenderDropdown(),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildDateField(context)),
          const SizedBox(width: 16),
          Expanded(child: _buildGenderDropdown()),
        ],
      );
    }
  }

  // Widget responsivo para información de contacto
  Widget _buildResponsiveContactInfo() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildTextField(_emailController, 'Correo Electrónico', Icons.email,
              TextInputType.emailAddress),
          SizedBox(height: 12),
          _buildTextField(
              _phoneController, 'Teléfono', Icons.phone, TextInputType.phone,
              isRequired: true),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildTextField(_emailController, 'Correo Electrónico',
                Icons.email, TextInputType.emailAddress),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
                _phoneController, 'Teléfono', Icons.phone, TextInputType.phone,
                isRequired: true),
          ),
        ],
      );
    }
  }

  Widget _buildDateField(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento',
            suffixIcon:
                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Género',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
        DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
      ],
      onChanged: (value) => setState(() => _gender = value),
      validator: (value) =>
          value == null ? 'Por favor seleccione un género' : null,
    );
  }

  Widget _buildResponsiveMedicalHistorySection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text('Historial Médico',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            )),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.all(isMobile ? 12 : 16),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        children: [
          // Wrap con checkboxes responsive
          Wrap(
            spacing: isMobile ? 8 : 16,
            runSpacing: isMobile ? 0 : 8,
            children: [
              _buildCheckboxRow('Alergias', _tieneAlergias,
                  (value) => setState(() => _tieneAlergias = value!)),
              _buildCheckboxRow('Respiratorias', _tieneRespiratorias,
                  (value) => setState(() => _tieneRespiratorias = value!)),
              _buildCheckboxRow(
                  'Alteraciones Nerviosas',
                  _tieneAlteracionesNerviosas,
                  (value) =>
                      setState(() => _tieneAlteracionesNerviosas = value!)),
              _buildCheckboxRow('Diabetes', _tieneDiabetes,
                  (value) => setState(() => _tieneDiabetes = value!)),
              _buildCheckboxRow('Renales', _tieneRenales,
                  (value) => setState(() => _tieneRenales = value!)),
              _buildCheckboxRow('Digestivos', _tieneDigestivos,
                  (value) => setState(() => _tieneDigestivos = value!)),
              _buildCheckboxRow('Cardiacos', _tieneCardiacos,
                  (value) => setState(() => _tieneCardiacos = value!)),
              _buildCheckboxRow('Tiroides', _tieneTiroides,
                  (value) => setState(() => _tieneTiroides = value!)),
              _buildCheckboxRow('Cirugías Previas', _tieneCirugiasPrevias,
                  (value) => setState(() => _tieneCirugiasPrevias = value!)),
              _buildCheckboxRow('Otras Condiciones', _tieneOtrasCondiciones,
                  (value) => setState(() => _tieneOtrasCondiciones = value!)),
            ],
          ),
          // Campos adicionales cuando están marcados los checkboxes
          if (_tieneAlergias)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildTextField(
                  _alergiasController, 'Especificar Alergias', null, null,
                  maxLines: 2),
            ),
          if (_tieneCirugiasPrevias)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildTextField(_cirugiasPreviasController,
                  'Especificar Cirugías Previas', null, null,
                  maxLines: 2),
            ),
          if (_tieneOtrasCondiciones)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildTextField(_otrasCondicionesController,
                  'Especificar Otras Condiciones', null, null,
                  maxLines: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveAestheticHistorySection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text('Historial Estético',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            )),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.all(isMobile ? 12 : 16),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        children: [
          Wrap(
            spacing: isMobile ? 8 : 16,
            runSpacing: isMobile ? 0 : 8,
            children: [
              _buildCheckboxRow('Productos Usados', _tieneProductosUsados,
                  (value) => setState(() => _tieneProductosUsados = value!)),
              _buildCheckboxRow('Otros Estéticos', _tieneOtrosEsteticos,
                  (value) => setState(() => _tieneOtrosEsteticos = value!)),
            ],
          ),
          if (_tieneProductosUsados)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildTextField(
                  _productosUsadosController, 'Productos Usados', null, null,
                  maxLines: 2),
            ),
          if (_tieneOtrosEsteticos)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildTextField(
                  _otrosEsteticosController, 'Otros Estéticos', null, null,
                  maxLines: 2),
            ),
          SizedBox(height: 16),
          _buildTextField(_tratamientosActualesController,
              'Tratamientos Actuales', null, null,
              maxLines: 2),
          SizedBox(height: 12),
          _buildTextField(_preferenciasTratamientoController,
              'Preferencias de Tratamiento', null, null,
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildHabitosVidaSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text('Hábitos de Vida',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            )),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.all(isMobile ? 12 : 16),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        children: [
          // Checkboxes para hábitos
          Wrap(
            spacing: isMobile ? 8 : 16,
            runSpacing: isMobile ? 0 : 8,
            children: [
              _buildCheckboxRow('Fumador', _fumador,
                  (value) => setState(() => _fumador = value!)),
              _buildCheckboxRow('Consume Alcohol', _consumeAlcohol,
                  (value) => setState(() => _consumeAlcohol = value!)),
              _buildCheckboxRow(
                  'Actividad Física Regular',
                  _actividadFisicaRegular,
                  (value) => setState(() => _actividadFisicaRegular = value!)),
              _buildCheckboxRow('Problemas del Sueño', _problemasDelSueno,
                  (value) => setState(() => _problemasDelSueno = value!)),
            ],
          ),
          SizedBox(height: 16),

          // Campos detallados de hábitos
          _buildTextField(
              _alimentacionController, 'Hábitos Alimenticios', null, null,
              maxLines: 2),
          SizedBox(height: 12),
          _buildTextField(_suenoController, 'Patrones de Sueño', null, null,
              maxLines: 2),
          SizedBox(height: 12),
          _buildTextField(_actividadFisicaController,
              'Detalle de Actividad Física', null, null,
              maxLines: 2),
          SizedBox(height: 12),
          _buildTextField(
              _consumoAguaController, 'Consumo de Agua Diario', null, null),
        ],
      ),
    );
  }

  Widget _buildMotivoConsultaSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motivo de Consulta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                )),
            SizedBox(height: 12),
            _buildTextField(
                _motivoConsultaController, 'Motivo de la Consulta', null, null,
                maxLines: 4, isRequired: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFichaTratamientoSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: isMobile ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ficha de Tratamiento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                )),
            SizedBox(height: 12),

            // Selector de tipo de tratamiento
            DropdownButtonFormField<String>(
              value: _tipoTratamiento,
              decoration: InputDecoration(
                labelText: 'Tipo de Tratamiento *',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'Facial', child: Text('Facial')),
                DropdownMenuItem(value: 'Corporal', child: Text('Corporal')),
                DropdownMenuItem(value: 'Bronceado', child: Text('Bronceado')),
              ],
              onChanged: (value) => setState(() => _tipoTratamiento = value),
              validator: (value) => value == null
                  ? 'Por favor seleccione un tipo de tratamiento'
                  : null,
            ),
            SizedBox(height: 16),

            // Secciones condicionales según el tipo de tratamiento
            if (_tipoTratamiento == 'Facial') _buildTratamientoFacialSection(),

            if (_tipoTratamiento == 'Corporal')
              _buildTratamientoCorporalSection(),

            if (_tipoTratamiento == 'Bronceado')
              _buildTratamientoBronceadoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTratamientoFacialSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    // En modo móvil, mantenemos el diseño vertical
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFacialSubsection(),
          SizedBox(height: 24),
          _buildDiagramSubsection(),
        ],
      );
    }
    // En tablet/desktop, usamos un diseño de dos columnas con cards
    else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda - Campos de tratamiento
          Expanded(
            flex: 2,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _buildFacialSubsection(),
              ),
            ),
          ),

          SizedBox(width: 20), // Espacio entre columnas

          // Columna derecha - Diagrama facial
          Expanded(
            flex: 3,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _buildDiagramSubsection(),
              ),
            ),
          ),
        ],
      );
    }
  }

// Extraemos el contenido del tratamiento facial a un método separado
  Widget _buildFacialSubsection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tratamiento Facial',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
              color: AppTheme.primaryColor,
            )),
        SizedBox(height: 16),

        // Campos para tratamiento facial
        _buildTextField(_tipoPielController, 'Tipo de Piel', null, null,
            isRequired: true),
        SizedBox(height: 16),
        _buildTextField(_estadoPielController, 'Estado', null, null,
            isRequired: true),
        SizedBox(height: 16),

        // Dropdown para grado de flacidez
        DropdownButtonFormField<String>(
          value: _gradoFlacidez,
          decoration: InputDecoration(
            labelText: 'Grado de Flacidez *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'Leve', child: Text('Leve')),
            DropdownMenuItem(value: 'Moderado', child: Text('Moderado')),
            DropdownMenuItem(value: 'Severo', child: Text('Severo')),
          ],
          onChanged: (value) => setState(() => _gradoFlacidez = value),
          validator: (value) =>
              value == null ? 'Este campo es requerido' : null,
        ),

        // Añadimos espacio y un separador visual para equilibrar con el diagrama
        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 16),

        // Instrucciones adicionales o notas para el tratamiento facial
        Text(
          'Notas importantes:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '• Evalúe las condiciones de la piel antes de comenzar',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '• Registre cualquier alergia o sensibilidad',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '• Observe cambios en la condición de la piel',
          style: TextStyle(fontSize: 14),
        ),

        // LISTA DE MARCAS FACIALES: Movida desde el widget FacialDiagramWidget
        SizedBox(height: 16),
        Text(
          'Marcas Faciales:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        _buildFacialMarksList(),
      ],
    );
  }

// Método para construir la lista de marcas faciales (replicando la del widget)

  Widget _buildFacialMarksList() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _facialMarks.isEmpty
          ? Center(
              child: Text(
                'No hay marcas faciales. Dibuja en el diagrama para añadir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _facialMarks.length,
              itemBuilder: (context, index) {
                final mark = _facialMarks[index];
                // Calcular el identificador para esta marca
                String markId = _getMarkId(mark.type, index);

                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: mark.getDisplayColor().withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: mark.getDisplayColor()),
                    ),
                    child: Center(
                      child: Text(
                        markId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: mark.getDisplayColor(),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  title:
                      Text('${mark.typeName} - ${_getShapeName(mark.shape)}'),
                  subtitle: mark.notes != null && mark.notes!.isNotEmpty
                      ? Text(mark.notes!, overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      _deleteMark(index);
                    },
                  ),
                  onTap: () {
                    _showMarkDetails(mark, index, markId);
                  },
                );
              },
            ),
    );
  }

// Método para calcular el identificador de una marca
  String _getMarkId(FacialMarkType type, int index) {
    final typePrefix = _getTypePrefix(type);
    int sequence = 1;

    // Encontrar la secuencia correcta contando marcas del mismo tipo
    for (int i = 0; i < index; i++) {
      if (_facialMarks[i].type == type) {
        sequence++;
      }
    }

    return "$typePrefix$sequence";
  }

// Método para obtener el prefijo según el tipo
  String _getTypePrefix(FacialMarkType type) {
    switch (type) {
      case FacialMarkType.marca:
        return "A";
      case FacialMarkType.eritema:
        return "B";
      case FacialMarkType.mancha:
        return "C";
      case FacialMarkType.lesion:
        return "D";
      case FacialMarkType.otro:
        return "E";
    }
  }

// Métodos auxiliares para la lista de marcas
  IconData _getIconForShape(FacialMarkShape shape) {
    switch (shape) {
      case FacialMarkShape.punto:
        return Icons.circle;
      case FacialMarkShape.circulo:
        return Icons.circle_outlined;
      case FacialMarkShape.area:
        return Icons.gesture;
    }
  }

  String _getShapeName(FacialMarkShape shape) {
    switch (shape) {
      case FacialMarkShape.punto:
        return 'Punto';
      case FacialMarkShape.circulo:
        return 'Círculo';
      case FacialMarkShape.area:
        return 'Área';
    }
  }

  void _deleteMark(int index) {
    if (index < 0 || index >= _facialMarks.length) return;

    setState(() {
      final updatedMarks = List<FacialMark>.from(_facialMarks);
      updatedMarks.removeAt(index);
      _updateFacialMarks(updatedMarks);
    });
  }

  void _showMarkDetails(FacialMark mark, int index, String markId) {
    final TextEditingController notesController =
        TextEditingController(text: mark.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: mark.getDisplayColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mark.getDisplayColor()),
              ),
              child: Text(
                markId,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mark.getDisplayColor(),
                ),
              ),
            ),
            SizedBox(width: 10),
            Text('Detalles de Marca'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${mark.typeName}'),
            Text('Forma: ${_getShapeName(mark.shape)}'),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Actualizar las notas
              final updatedMark = FacialMark(
                type: mark.type,
                shape: mark.shape,
                x: mark.x,
                y: mark.y,
                radius: mark.radius,
                points: mark.points,
                notes: notesController.text,
              );

              setState(() {
                final updatedMarks = List<FacialMark>.from(_facialMarks);
                updatedMarks[index] = updatedMark;
                _updateFacialMarks(updatedMarks);
              });
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

// Extraemos el contenido del diagrama facial a un método separado
  Widget _buildDiagramSubsection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diagrama Facial',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
              color: AppTheme.primaryColor,
            )),
        SizedBox(height: 16),

        Text(
          'Marque en el diagrama las lesiones o condiciones presentes:',
          style: TextStyle(fontSize: isMobile ? 12 : 14),
        ),
        SizedBox(height: 12),

        // Contenedor del diagrama con borde suave
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FacialDiagramWidget(
            marks: _facialMarks,
            onMarksChanged: _updateFacialMarks,
            width: isMobile ? 300 : 360,
            height: isMobile ? 400 : 420,
          ),
        ),
      ],
    );
  }

  Widget _buildTratamientoCorporalSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Medidas (cm)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
              color: AppTheme.primaryColor,
            )),
        SizedBox(height: 12),

        // Medidas corporales
        Row(
          children: [
            Expanded(
                child: _buildTextField(_abdomenAltoController, 'Abdomen Alto',
                    null, TextInputType.number)),
            SizedBox(width: 16),
            Expanded(
                child: _buildTextField(_abdomenBajoController, 'Abdomen Bajo',
                    null, TextInputType.number)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildTextField(
                    _cinturaController, 'Cintura', null, TextInputType.number)),
            SizedBox(width: 16),
            Expanded(
                child: _buildTextField(
                    _espaldaController, 'Espalda', null, TextInputType.number)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildTextField(_brazoIzqController, 'Brazo Izquierdo',
                    null, TextInputType.number)),
            SizedBox(width: 16),
            Expanded(
                child: _buildTextField(_brazoDerechoController, 'Brazo Derecho',
                    null, TextInputType.number)),
          ],
        ),

        SizedBox(height: 24),
        Text('Antropología',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
              color: AppTheme.primaryColor,
            )),
        SizedBox(height: 12),

        // Campos antropología
        Row(
          children: [
            Expanded(
              child: _buildTextField(_pesoActualController, 'Peso Actual (kg)',
                  null, TextInputType.number),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                  _alturaController, 'Altura (cm)', null, TextInputType.number),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Botón para calcular IMC
        ElevatedButton.icon(
          onPressed: _calcularIMC,
          icon: Icon(Icons.calculate),
          label: Text('Calcular IMC'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTextColor,
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 12),

        // Resultados IMC
        if (_imc != null)
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IMC: $_imc',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Clasificación: $_nivelObesidad'),
                ],
              ),
            ),
          ),

        SizedBox(height: 24),
        Text('Patologías',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
              color: AppTheme.primaryColor,
            )),
        SizedBox(height: 12),

        // Celulitis
        _buildCheckboxRow('Celulitis', _tieneCelulitis,
            (value) => setState(() => _tieneCelulitis = value!)),

        if (_tieneCelulitis) ...[
          SizedBox(height: 12),
          // Dropdown para grado de celulitis
          DropdownButtonFormField<String>(
            value: _gradoCelulitis,
            decoration: InputDecoration(
              labelText: 'Grado de Celulitis',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Grado I', child: Text('Grado I')),
              DropdownMenuItem(value: 'Grado II', child: Text('Grado II')),
              DropdownMenuItem(value: 'Grado III', child: Text('Grado III')),
              DropdownMenuItem(value: 'Grado IV', child: Text('Grado IV')),
            ],
            onChanged: (value) => setState(() => _gradoCelulitis = value),
          ),
          SizedBox(height: 12),
          _buildTextField(
              _lugarCelulitisController, 'Lugar de Celulitis', null, null),
        ],

        SizedBox(height: 12),
        // Estrías
        _buildCheckboxRow('Estrías', _tieneEstrias,
            (value) => setState(() => _tieneEstrias = value!)),

        if (_tieneEstrias) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      _colorEstriasController, 'Color de Estrías', null, null)),
              SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(_tiempoEstriasController,
                      'Tiempo de Estrías', null, null)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTratamientoBronceadoSection() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tratamiento de Bronceado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
              color: AppTheme.primaryColor,
            )),
        SizedBox(height: 12),

        // Dropdown para escala Glasgow
        DropdownButtonFormField<String>(
          value: _escalaGlasgow,
          decoration: InputDecoration(
            labelText: 'Escala de Glasgow *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: '3-8 (Grave)', child: Text('3-8 (Grave)')),
            DropdownMenuItem(
                value: '9-12 (Moderado)', child: Text('9-12 (Moderado)')),
            DropdownMenuItem(
                value: '13-15 (Leve)', child: Text('13-15 (Leve)')),
          ],
          onChanged: (value) => setState(() => _escalaGlasgow = value),
          validator: (value) =>
              value == null ? 'Este campo es requerido' : null,
        ),
        SizedBox(height: 16),

        // Dropdown para escala Fitzpatrick
        DropdownButtonFormField<String>(
          value: _escalaFitzpatrick,
          decoration: InputDecoration(
            labelText: 'Escala Fitzpatrick *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(
                value: 'Tipo I',
                child: Text('Tipo I - Piel muy clara, siempre se quema')),
            DropdownMenuItem(
                value: 'Tipo II',
                child: Text('Tipo II - Piel clara, se quema fácilmente')),
            DropdownMenuItem(
                value: 'Tipo III',
                child: Text('Tipo III - Piel media, a veces se quema')),
            DropdownMenuItem(
                value: 'Tipo IV',
                child: Text('Tipo IV - Piel oliva, raramente se quema')),
            DropdownMenuItem(
                value: 'Tipo V',
                child: Text('Tipo V - Piel morena, muy raramente se quema')),
            DropdownMenuItem(
                value: 'Tipo VI',
                child: Text('Tipo VI - Piel oscura, nunca se quema')),
          ],
          onChanged: (value) => setState(() => _escalaFitzpatrick = value),
          validator: (value) =>
              value == null ? 'Este campo es requerido' : null,
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(
      String label, bool value, Function(bool?) onChanged) {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width - 80) / 2 : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: isMobile ? 0.9 : 1.0,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Flexible(
            child: Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return ElevatedButton(
      onPressed: _isLoading ? null : _addClient,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text('Guardar Cliente',
              style: TextStyle(fontSize: isMobile ? 14 : 16)),
    );
  }
}
