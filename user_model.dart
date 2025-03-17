//lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'facial_mark_model.dart';

enum UserRole { client, admin, therapist, receptionist }

class UserModel {
  final String id;
  final String name;
  final String lastName;
  final String? cedula;
  final String? ocupacion;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? birthDate;
  final String? gender;
  final String? photoUrl;
  final String? medicalNotes;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // Historial médico
  final bool? tieneAlergias;
  final String? alergias;
  final bool? tieneRespiratorias;
  final bool? tieneAlteracionesNerviosas;
  final bool? tieneDiabetes;
  final bool? tieneRenales;
  final bool? tieneDigestivos;
  final bool? tieneCardiacos;
  final bool? tieneTiroides;
  final bool? tieneCirugiasPrevias;
  final String? cirugiasPrevias;
  final bool? tieneOtrasCondiciones;
  final String? otrasCondiciones;
  // Campos antiguos para compatibilidad
  final bool? tieneAsma;
  final bool? tieneHipertension;
  final bool? tieneCancer;

  // Historial estético
  final bool? tieneProductosUsados;
  final String? productosUsados;
  final bool? tieneOtrosEsteticos;
  final String? otrosEsteticos;
  final String? tratamientosActuales;
  final String? preferenciasTratamiento;
  // Campos antiguos para compatibilidad
  final bool? tieneProcedimientosEsteticosPrevios;
  final String? procedimientosEsteticosPrevios;
  final bool? tieneCirugias;
  final String? cirugias;
  final bool? tieneImplantes;
  final String? implantes;

  // Motivo de consulta
  final String? motivoConsulta;

  // Hábitos de vida (nuevos)
  final bool? fumador;
  final bool? consumeAlcohol;
  final bool? actividadFisicaRegular;
  final bool? problemasDelSueno;
  final String? alimentacion;
  final String? sueno;
  final String? actividadFisica;
  final String? consumoAgua;

  // Ficha de tratamiento
  final String? tipoTratamiento;
  final List<FacialMark>? facialMarks; // NUEVO: Marcas del diagrama facial

  // Tratamiento Facial
  final String? tipoPiel;
  final String? estadoPiel;
  final String? gradoFlacidez;

  // Tratamiento Corporal - Medidas
  final String? abdomenAlto;
  final String? abdomenBajo;
  final String? cintura;
  final String? espalda;
  final String? brazoIzq;
  final String? brazoDerecho;

  // Tratamiento Corporal - Antropología
  final String? pesoActual;
  final String? altura;
  final String? imc;
  final String? nivelObesidad;

  // Tratamiento Corporal - Patologías
  final bool? tieneCelulitis;
  final String? gradoCelulitis;
  final String? lugarCelulitis;
  final bool? tieneEstrias;
  final String? colorEstrias;
  final String? tiempoEstrias;

  // Tratamiento Bronceado
  final String? escalaGlasgow;
  final String? escalaFitzpatrick;

  UserModel({
    required this.id,
    required this.name,
    required this.lastName,
    this.cedula,
    this.ocupacion,
    this.email,
    this.phone,
    this.address,
    this.birthDate,
    this.gender,
    this.photoUrl,
    this.medicalNotes,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    // Historial médico
    this.tieneAlergias,
    this.alergias,
    this.tieneRespiratorias,
    this.tieneAlteracionesNerviosas,
    this.tieneDiabetes,
    this.tieneRenales,
    this.tieneDigestivos,
    this.tieneCardiacos,
    this.tieneTiroides,
    this.tieneCirugiasPrevias,
    this.cirugiasPrevias,
    this.tieneOtrasCondiciones,
    this.otrasCondiciones,
    // Campos antiguos para compatibilidad
    this.tieneAsma,
    this.tieneHipertension,
    this.tieneCancer,
    // Historial estético
    this.tieneProductosUsados,
    this.productosUsados,
    this.tieneOtrosEsteticos,
    this.otrosEsteticos,
    this.tratamientosActuales,
    this.preferenciasTratamiento,
    // Campos antiguos para compatibilidad
    this.tieneProcedimientosEsteticosPrevios,
    this.procedimientosEsteticosPrevios,
    this.tieneCirugias,
    this.cirugias,
    this.tieneImplantes,
    this.implantes,
    // Motivo de consulta
    this.motivoConsulta,
    // Hábitos de vida
    this.fumador,
    this.consumeAlcohol,
    this.actividadFisicaRegular,
    this.problemasDelSueno,
    this.alimentacion,
    this.sueno,
    this.actividadFisica,
    this.consumoAgua,
    // Ficha de tratamiento
    this.tipoTratamiento,
    this.facialMarks, // NUEVO
    // Tratamiento Facial
    this.tipoPiel,
    this.estadoPiel,
    this.gradoFlacidez,
    // Tratamiento Corporal - Medidas
    this.abdomenAlto,
    this.abdomenBajo,
    this.cintura,
    this.espalda,
    this.brazoIzq,
    this.brazoDerecho,
    // Tratamiento Corporal - Antropología
    this.pesoActual,
    this.altura,
    this.imc,
    this.nivelObesidad,
    // Tratamiento Corporal - Patologías
    this.tieneCelulitis,
    this.gradoCelulitis,
    this.lugarCelulitis,
    this.tieneEstrias,
    this.colorEstrias,
    this.tiempoEstrias,
    // Tratamiento Bronceado
    this.escalaGlasgow,
    this.escalaFitzpatrick,
  });

  String get fullName => '$name $lastName';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      cedula: data['cedula'],
      ocupacion: data['ocupacion'],
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      gender: data['gender'],
      photoUrl: data['photoUrl'],
      medicalNotes: data['medicalNotes'],
      role: roleFromString(data['role'] ?? 'client'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      // Historial médico
      tieneAlergias: data['tieneAlergias'],
      alergias: data['alergias'],
      tieneRespiratorias: data['tieneRespiratorias'],
      tieneAlteracionesNerviosas: data['tieneAlteracionesNerviosas'],
      tieneDiabetes: data['tieneDiabetes'],
      tieneRenales: data['tieneRenales'],
      tieneDigestivos: data['tieneDigestivos'],
      tieneCardiacos: data['tieneCardiacos'],
      tieneTiroides: data['tieneTiroides'],
      tieneCirugiasPrevias: data['tieneCirugiasPrevias'],
      cirugiasPrevias: data['cirugiasPrevias'],
      tieneOtrasCondiciones: data['tieneOtrasCondiciones'],
      otrasCondiciones: data['otrasCondiciones'],
      // Campos antiguos para compatibilidad
      tieneAsma: data['tieneAsma'],
      tieneHipertension: data['tieneHipertension'],
      tieneCancer: data['tieneCancer'],
      // Historial estético
      tieneProductosUsados: data['tieneProductosUsados'],
      productosUsados: data['productosUsados'],
      tieneOtrosEsteticos: data['tieneOtrosEsteticos'],
      otrosEsteticos: data['otrosEsteticos'],
      tratamientosActuales: data['tratamientosActuales'],
      preferenciasTratamiento: data['preferenciasTratamiento'],
      // Campos antiguos para compatibilidad
      tieneProcedimientosEsteticosPrevios:
          data['tieneProcedimientosEsteticosPrevios'],
      procedimientosEsteticosPrevios: data['procedimientosEsteticosPrevios'],
      tieneCirugias: data['tieneCirugias'],
      cirugias: data['cirugias'],
      tieneImplantes: data['tieneImplantes'],
      implantes: data['implantes'],
      // Motivo de consulta
      motivoConsulta: data['motivoConsulta'],
      // Hábitos de vida
      fumador: data['fumador'],
      consumeAlcohol: data['consumeAlcohol'],
      actividadFisicaRegular: data['actividadFisicaRegular'],
      problemasDelSueno: data['problemasDelSueno'],
      alimentacion: data['alimentacion'],
      sueno: data['sueno'],
      actividadFisica: data['actividadFisica'],
      consumoAgua: data['consumoAgua'],
      // Ficha de tratamiento
      tipoTratamiento: data['tipoTratamiento'],
      // NUEVO: Marcas faciales
      facialMarks: data['facialMarks'] != null
          ? (data['facialMarks'] as List)
              .map((markData) =>
                  FacialMark.fromJson(Map<String, dynamic>.from(markData)))
              .toList()
          : null,
      // Tratamiento Facial
      tipoPiel: data['tipoPiel'],
      estadoPiel: data['estadoPiel'],
      gradoFlacidez: data['gradoFlacidez'],
      // Tratamiento Corporal - Medidas
      abdomenAlto: data['abdomenAlto'],
      abdomenBajo: data['abdomenBajo'],
      cintura: data['cintura'],
      espalda: data['espalda'],
      brazoIzq: data['brazoIzq'],
      brazoDerecho: data['brazoDerecho'],
      // Tratamiento Corporal - Antropología
      pesoActual: data['pesoActual'],
      altura: data['altura'],
      imc: data['imc'],
      nivelObesidad: data['nivelObesidad'],
      // Tratamiento Corporal - Patologías
      tieneCelulitis: data['tieneCelulitis'],
      gradoCelulitis: data['gradoCelulitis'],
      lugarCelulitis: data['lugarCelulitis'],
      tieneEstrias: data['tieneEstrias'],
      colorEstrias: data['colorEstrias'],
      tiempoEstrias: data['tiempoEstrias'],
      // Tratamiento Bronceado
      escalaGlasgow: data['escalaGlasgow'],
      escalaFitzpatrick: data['escalaFitzpatrick'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'cedula': cedula,
      'ocupacion': ocupacion,
      'email': email,
      'phone': phone,
      'address': address,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'photoUrl': photoUrl,
      'medicalNotes': medicalNotes,
      'role': _roleToString(role),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      // Historial médico
      'tieneAlergias': tieneAlergias,
      'alergias': alergias,
      'tieneRespiratorias': tieneRespiratorias,
      'tieneAlteracionesNerviosas': tieneAlteracionesNerviosas,
      'tieneDiabetes': tieneDiabetes,
      'tieneRenales': tieneRenales,
      'tieneDigestivos': tieneDigestivos,
      'tieneCardiacos': tieneCardiacos,
      'tieneTiroides': tieneTiroides,
      'tieneCirugiasPrevias': tieneCirugiasPrevias,
      'cirugiasPrevias': cirugiasPrevias,
      'tieneOtrasCondiciones': tieneOtrasCondiciones,
      'otrasCondiciones': otrasCondiciones,
      // Campos antiguos para compatibilidad
      'tieneAsma': tieneAsma,
      'tieneHipertension': tieneHipertension,
      'tieneCancer': tieneCancer,
      // Historial estético
      'tieneProductosUsados': tieneProductosUsados,
      'productosUsados': productosUsados,
      'tieneOtrosEsteticos': tieneOtrosEsteticos,
      'otrosEsteticos': otrosEsteticos,
      'tratamientosActuales': tratamientosActuales,
      'preferenciasTratamiento': preferenciasTratamiento,
      // Campos antiguos para compatibilidad
      'tieneProcedimientosEsteticosPrevios':
          tieneProcedimientosEsteticosPrevios,
      'procedimientosEsteticosPrevios': procedimientosEsteticosPrevios,
      'tieneCirugias': tieneCirugias,
      'cirugias': cirugias,
      'tieneImplantes': tieneImplantes,
      'implantes': implantes,
      // Motivo de consulta
      'motivoConsulta': motivoConsulta,
      // Hábitos de vida
      'fumador': fumador,
      'consumeAlcohol': consumeAlcohol,
      'actividadFisicaRegular': actividadFisicaRegular,
      'problemasDelSueno': problemasDelSueno,
      'alimentacion': alimentacion,
      'sueno': sueno,
      'actividadFisica': actividadFisica,
      'consumoAgua': consumoAgua,
      // Ficha de tratamiento
      'tipoTratamiento': tipoTratamiento,
      // NUEVO: Marcas faciales
      'facialMarks': facialMarks?.map((mark) => mark.toJson()).toList(),
      // Tratamiento Facial
      'tipoPiel': tipoPiel,
      'estadoPiel': estadoPiel,
      'gradoFlacidez': gradoFlacidez,
      // Tratamiento Corporal - Medidas
      'abdomenAlto': abdomenAlto,
      'abdomenBajo': abdomenBajo,
      'cintura': cintura,
      'espalda': espalda,
      'brazoIzq': brazoIzq,
      'brazoDerecho': brazoDerecho,
      // Tratamiento Corporal - Antropología
      'pesoActual': pesoActual,
      'altura': altura,
      'imc': imc,
      'nivelObesidad': nivelObesidad,
      // Tratamiento Corporal - Patologías
      'tieneCelulitis': tieneCelulitis,
      'gradoCelulitis': gradoCelulitis,
      'lugarCelulitis': lugarCelulitis,
      'tieneEstrias': tieneEstrias,
      'colorEstrias': colorEstrias,
      'tiempoEstrias': tiempoEstrias,
      // Tratamiento Bronceado
      'escalaGlasgow': escalaGlasgow,
      'escalaFitzpatrick': escalaFitzpatrick,
    };
  }

  static UserRole roleFromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'therapist':
        return UserRole.therapist;
      case 'receptionist':
        return UserRole.receptionist;
      case 'client':
      default:
        return UserRole.client;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.therapist:
        return 'therapist';
      case UserRole.receptionist:
        return 'receptionist';
      case UserRole.client:
      default:
        return 'client';
    }
  }

  UserModel copyWith({
    String? name,
    String? lastName,
    String? cedula,
    String? ocupacion,
    String? email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? photoUrl,
    String? medicalNotes,
    UserRole? role,
    DateTime? updatedAt,
    bool? isActive,
    // Historial médico
    bool? tieneAlergias,
    String? alergias,
    bool? tieneRespiratorias,
    bool? tieneAlteracionesNerviosas,
    bool? tieneDiabetes,
    bool? tieneRenales,
    bool? tieneDigestivos,
    bool? tieneCardiacos,
    bool? tieneTiroides,
    bool? tieneCirugiasPrevias,
    String? cirugiasPrevias,
    bool? tieneOtrasCondiciones,
    String? otrasCondiciones,
    // Campos antiguos para compatibilidad
    bool? tieneAsma,
    bool? tieneHipertension,
    bool? tieneCancer,
    // Historial estético
    bool? tieneProductosUsados,
    String? productosUsados,
    bool? tieneOtrosEsteticos,
    String? otrosEsteticos,
    String? tratamientosActuales,
    String? preferenciasTratamiento,
    // Campos antiguos para compatibilidad
    bool? tieneProcedimientosEsteticosPrevios,
    String? procedimientosEsteticosPrevios,
    bool? tieneCirugias,
    String? cirugias,
    bool? tieneImplantes,
    String? implantes,
    // Motivo de consulta
    String? motivoConsulta,
    // Hábitos de vida
    bool? fumador,
    bool? consumeAlcohol,
    bool? actividadFisicaRegular,
    bool? problemasDelSueno,
    String? alimentacion,
    String? sueno,
    String? actividadFisica,
    String? consumoAgua,
    // Ficha de tratamiento
    String? tipoTratamiento,
    List<FacialMark>? facialMarks, // NUEVO
    // Tratamiento Facial
    String? tipoPiel,
    String? estadoPiel,
    String? gradoFlacidez,
    // Tratamiento Corporal - Medidas
    String? abdomenAlto,
    String? abdomenBajo,
    String? cintura,
    String? espalda,
    String? brazoIzq,
    String? brazoDerecho,
    // Tratamiento Corporal - Antropología
    String? pesoActual,
    String? altura,
    String? imc,
    String? nivelObesidad,
    // Tratamiento Corporal - Patologías
    bool? tieneCelulitis,
    String? gradoCelulitis,
    String? lugarCelulitis,
    bool? tieneEstrias,
    String? colorEstrias,
    String? tiempoEstrias,
    // Tratamiento Bronceado
    String? escalaGlasgow,
    String? escalaFitzpatrick,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      cedula: cedula ?? this.cedula,
      ocupacion: ocupacion ?? this.ocupacion,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      role: role ?? this.role,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      // Historial médico
      tieneAlergias: tieneAlergias ?? this.tieneAlergias,
      alergias: alergias ?? this.alergias,
      tieneRespiratorias: tieneRespiratorias ?? this.tieneRespiratorias,
      tieneAlteracionesNerviosas:
          tieneAlteracionesNerviosas ?? this.tieneAlteracionesNerviosas,
      tieneDiabetes: tieneDiabetes ?? this.tieneDiabetes,
      tieneRenales: tieneRenales ?? this.tieneRenales,
      tieneDigestivos: tieneDigestivos ?? this.tieneDigestivos,
      tieneCardiacos: tieneCardiacos ?? this.tieneCardiacos,
      tieneTiroides: tieneTiroides ?? this.tieneTiroides,
      tieneCirugiasPrevias: tieneCirugiasPrevias ?? this.tieneCirugiasPrevias,
      cirugiasPrevias: cirugiasPrevias ?? this.cirugiasPrevias,
      tieneOtrasCondiciones:
          tieneOtrasCondiciones ?? this.tieneOtrasCondiciones,
      otrasCondiciones: otrasCondiciones ?? this.otrasCondiciones,
      // Campos antiguos para compatibilidad
      tieneAsma: tieneAsma ?? this.tieneAsma,
      tieneHipertension: tieneHipertension ?? this.tieneHipertension,
      tieneCancer: tieneCancer ?? this.tieneCancer,
      // Historial estético
      tieneProductosUsados: tieneProductosUsados ?? this.tieneProductosUsados,
      productosUsados: productosUsados ?? this.productosUsados,
      tieneOtrosEsteticos: tieneOtrosEsteticos ?? this.tieneOtrosEsteticos,
      otrosEsteticos: otrosEsteticos ?? this.otrosEsteticos,
      tratamientosActuales: tratamientosActuales ?? this.tratamientosActuales,
      preferenciasTratamiento:
          preferenciasTratamiento ?? this.preferenciasTratamiento,
      // Campos antiguos para compatibilidad
      tieneProcedimientosEsteticosPrevios:
          tieneProcedimientosEsteticosPrevios ??
              this.tieneProcedimientosEsteticosPrevios,
      procedimientosEsteticosPrevios:
          procedimientosEsteticosPrevios ?? this.procedimientosEsteticosPrevios,
      tieneCirugias: tieneCirugias ?? this.tieneCirugias,
      cirugias: cirugias ?? this.cirugias,
      tieneImplantes: tieneImplantes ?? this.tieneImplantes,
      implantes: implantes ?? this.implantes,
      // Motivo de consulta
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      // Hábitos de vida
      fumador: fumador ?? this.fumador,
      consumeAlcohol: consumeAlcohol ?? this.consumeAlcohol,
      actividadFisicaRegular:
          actividadFisicaRegular ?? this.actividadFisicaRegular,
      problemasDelSueno: problemasDelSueno ?? this.problemasDelSueno,
      alimentacion: alimentacion ?? this.alimentacion,
      sueno: sueno ?? this.sueno,
      actividadFisica: actividadFisica ?? this.actividadFisica,
      consumoAgua: consumoAgua ?? this.consumoAgua,
      // Ficha de tratamiento
      tipoTratamiento: tipoTratamiento ?? this.tipoTratamiento,
      facialMarks: facialMarks ?? this.facialMarks, // NUEVO
      // Tratamiento Facial
      tipoPiel: tipoPiel ?? this.tipoPiel,
      estadoPiel: estadoPiel ?? this.estadoPiel,
      gradoFlacidez: gradoFlacidez ?? this.gradoFlacidez,
      // Tratamiento Corporal - Medidas
      abdomenAlto: abdomenAlto ?? this.abdomenAlto,
      abdomenBajo: abdomenBajo ?? this.abdomenBajo,
      cintura: cintura ?? this.cintura,
      espalda: espalda ?? this.espalda,
      brazoIzq: brazoIzq ?? this.brazoIzq,
      brazoDerecho: brazoDerecho ?? this.brazoDerecho,
      // Tratamiento Corporal - Antropología
      pesoActual: pesoActual ?? this.pesoActual,
      altura: altura ?? this.altura,
      imc: imc ?? this.imc,
      nivelObesidad: nivelObesidad ?? this.nivelObesidad,
      // Tratamiento Corporal - Patologías
      tieneCelulitis: tieneCelulitis ?? this.tieneCelulitis,
      gradoCelulitis: gradoCelulitis ?? this.gradoCelulitis,
      lugarCelulitis: lugarCelulitis ?? this.lugarCelulitis,
      tieneEstrias: tieneEstrias ?? this.tieneEstrias,
      colorEstrias: colorEstrias ?? this.colorEstrias,
      tiempoEstrias: tiempoEstrias ?? this.tiempoEstrias,
      // Tratamiento Bronceado
      escalaGlasgow: escalaGlasgow ?? this.escalaGlasgow,
      escalaFitzpatrick: escalaFitzpatrick ?? this.escalaFitzpatrick,
    );
  }
}
