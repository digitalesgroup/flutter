// lib/widgets/client_widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/transaction_model.dart';
import '../models/facial_mark_model.dart'; // NUEVO
import '../painters/facial_diagram_painter.dart'; // NUEVO
import '../services/database_service.dart';
import 'common_widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Design constants
class AppStyles {
  // Colors
  static const Color primaryColor = Color(0xFF0057FF);
  static const Color surfaceColor = Color(0xFFF8F9FB);
  static const Color textColor = Color(0xFF1C2025);
  static const Color secondaryTextColor = Color(0xFF6F7580);
  static const Color successColor = Color(0xFF00C27E);
  static const Color errorColor = Color(0xFFFF4D4F);
  static const Color warningColor = Color(0xFFFFA940);
  static const Color dividerColor = Color(0xFFE8E9EC);

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Shadows
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: textColor.withOpacity(0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: textColor.withOpacity(0.08),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  // Typography
  static TextStyle get headingLarge => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textColor,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textColor,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textColor,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: textColor,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: textColor,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: secondaryTextColor,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: secondaryTextColor,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: secondaryTextColor,
      );
}

// Client Avatar Widget
class ClientAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final String? name;

  const ClientAvatar({
    this.photoUrl,
    this.size = 40,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;
    final initial =
        name != null && name!.isNotEmpty ? name![0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasPhoto ? null : AppStyles.primaryColor.withOpacity(0.1),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: AppStyles.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: size * 0.4,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppStyles.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.4,
                  ),
                ),
              ),
      ),
    );
  }
}

// Client List Item Widget
class ClientListItem extends StatelessWidget {
  final UserModel client;
  final VoidCallback onTap;

  const ClientListItem({
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingM,
        vertical: AppStyles.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            child: Row(
              children: [
                ClientAvatar(
                  photoUrl: client.photoUrl,
                  name: client.name,
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.fullName,
                        style: AppStyles.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (client.phone != null) ...[
                        const SizedBox(height: AppStyles.spacingXS),
                        Text(
                          client.phone!,
                          style: AppStyles.bodySmall,
                        ),
                      ] else ...[
                        const SizedBox(height: AppStyles.spacingXS),
                        Text(
                          'Sin teléfono',
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppStyles.secondaryTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Redesigned ClientInfoCard Widget
class ClientInfoCard extends StatelessWidget {
  final UserModel client;

  const ClientInfoCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        boxShadow: AppStyles.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with client photo and basic info
          _buildHeader(context),

          // Main content with two-column layout for larger screens
          isMobile ? _buildMobileContent() : _buildDesktopContent(),
        ],
      ),
    );
  }

  // Header with client photo and basic contact info
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppStyles.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientAvatar(
            photoUrl: client.photoUrl,
            name: client.name,
            size: 64,
          ),
          const SizedBox(width: AppStyles.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: AppStyles.headingMedium,
                ),
                if (client.email != null || client.phone != null) ...[
                  const SizedBox(height: AppStyles.spacingS),
                  Wrap(
                    spacing: AppStyles.spacingL,
                    children: [
                      if (client.email != null)
                        _buildContactInfo(Icons.email_outlined, client.email!),
                      if (client.phone != null)
                        _buildContactInfo(Icons.phone_outlined, client.phone!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build contact info items
  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppStyles.secondaryTextColor,
        ),
        const SizedBox(width: AppStyles.spacingXS),
        Text(
          text,
          style: AppStyles.bodyMedium.copyWith(
            color: AppStyles.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  // Mobile layout (single column)
  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information
        _buildSection(
          'Información Personal',
          children: _buildPersonalInfoItems(),
        ),

        // Motivo de Consulta
        if (client.motivoConsulta != null && client.motivoConsulta!.isNotEmpty)
          _buildSection(
            'Motivo de Consulta',
            children: [
              _buildInfoRow(
                Icons.question_answer_outlined,
                'Motivo de Consulta',
                client.motivoConsulta!,
              ),
            ],
          ),

        // Medical History
        _buildSection(
          'Historial Médico',
          children: _buildMedicalHistoryItems(),
        ),

        // Aesthetic History
        _buildSection(
          'Historial Estético',
          children: _buildAestheticHistoryItems(),
        ),

        // Hábitos de Vida
        _buildSection(
          'Hábitos de Vida',
          children: _buildLifestyleItems(),
        ),

        // Ficha de Tratamiento
        if (client.tipoTratamiento != null)
          _buildSection(
            'Ficha de Tratamiento',
            isLast: true,
            children: _buildTreatmentItems(),
          ),
      ],
    );
  }

  // Desktop layout (two columns)
  Widget _buildDesktopContent() {
    // List of sections to display
    final sections = <Widget>[];

    // Row 1: Personal Information and Medical History
    if (_buildPersonalInfoItems().isNotEmpty ||
        _buildMedicalHistoryItems().isNotEmpty) {
      sections.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Personal Information
              Expanded(
                child: _buildSection(
                  'Información Personal',
                  hasBorder: false,
                  children: _buildPersonalInfoItems(),
                ),
              ),
              // Vertical divider
              Container(
                width: 1,
                color: AppStyles.dividerColor,
              ),
              // Right column: Medical History
              Expanded(
                child: _buildSection(
                  'Historial Médico',
                  hasBorder: false,
                  children: _buildMedicalHistoryItems(),
                ),
              ),
            ],
          ),
        ),
      );

      sections.add(
        Container(
          height: 1,
          color: AppStyles.dividerColor,
        ),
      );
    }

    // Motivo de Consulta
    if (client.motivoConsulta != null && client.motivoConsulta!.isNotEmpty) {
      sections.add(
        _buildSection(
          'Motivo de Consulta',
          children: [
            _buildInfoRow(
              Icons.question_answer_outlined,
              'Motivo de Consulta',
              client.motivoConsulta!,
            ),
          ],
        ),
      );

      sections.add(
        Container(
          height: 1,
          color: AppStyles.dividerColor,
        ),
      );
    }

    // Row 2: Aesthetic History and Lifestyle
    if (_buildAestheticHistoryItems().isNotEmpty ||
        _buildLifestyleItems().isNotEmpty) {
      sections.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Aesthetic History
              Expanded(
                child: _buildSection(
                  'Historial Estético',
                  hasBorder: false,
                  children: _buildAestheticHistoryItems(),
                ),
              ),
              // Vertical divider
              Container(
                width: 1,
                color: AppStyles.dividerColor,
              ),
              // Right column: Lifestyle
              Expanded(
                child: _buildSection(
                  'Hábitos de Vida',
                  hasBorder: false,
                  children: _buildLifestyleItems(),
                ),
              ),
            ],
          ),
        ),
      );

      sections.add(
        Container(
          height: 1,
          color: AppStyles.dividerColor,
        ),
      );
    }

    // Treatment section (if available)
    if (client.tipoTratamiento != null) {
      sections.add(
        _buildSection(
          'Ficha de Tratamiento',
          isLast: true,
          children: _buildTreatmentItems(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  // Common method to build a section with a title
  Widget _buildSection(
    String title, {
    required List<Widget> children,
    bool isLast = false,
    bool hasBorder = true,
  }) {
    // Filtra los widgets nulos o vacíos
    final validChildren =
        children.where((child) => child != Container()).toList();

    // Si no hay contenido válido, no muestra la sección
    if (validChildren.isEmpty) {
      return Container();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        border: hasBorder && !isLast
            ? const Border(
                bottom: BorderSide(
                  color: AppStyles.dividerColor,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: AppStyles.spacingM),
          ...validChildren,
        ],
      ),
    );
  }

  // Generate personal information items
  List<Widget> _buildPersonalInfoItems() {
    return [
      Wrap(
        spacing: AppStyles.spacingL,
        runSpacing: AppStyles.spacingM,
        children: [
          if (client.cedula != null && client.cedula!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.badge_outlined,
              'Cédula',
              client.cedula!,
            ),
          if (client.ocupacion != null && client.ocupacion!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.work_outline,
              'Ocupación',
              client.ocupacion!,
            ),
          if (client.birthDate != null)
            _buildCompactInfoItem(
              Icons.cake_outlined,
              'Fecha de Nacimiento',
              DateFormat('dd/MM/yyyy').format(client.birthDate!),
            ),
          if (client.gender != null)
            _buildCompactInfoItem(
              Icons.wc_outlined,
              'Género',
              client.gender!,
            ),
          if (client.address != null)
            _buildCompactInfoItem(
              Icons.home_outlined,
              'Dirección',
              client.address!,
            ),
        ],
      ),
    ];
  }

  // Generate medical history items
  List<Widget> _buildMedicalHistoryItems() {
    return [
      // Medical conditions as tags
      Wrap(
        spacing: AppStyles.spacingS,
        runSpacing: AppStyles.spacingS,
        children: [
          if (client.tieneDiabetes ?? false) _buildConditionTag('Diabetes'),
          if (client.tieneAsma ?? false) _buildConditionTag('Asma'),
          if (client.tieneHipertension ?? false)
            _buildConditionTag('Hipertensión'),
          if (client.tieneCancer ?? false) _buildConditionTag('Cáncer'),
        ],
      ),

      if ((client.tieneDiabetes ?? false) ||
          (client.tieneAsma ?? false) ||
          (client.tieneHipertension ?? false) ||
          (client.tieneCancer ?? false))
        const SizedBox(height: AppStyles.spacingM),

      if (client.tieneAlergias ?? false)
        _buildCompactInfoItem(
          Icons.warning_amber_outlined,
          'Alergias',
          client.alergias ?? 'No especificado',
          iconColor: AppStyles.warningColor,
        ),

      if (client.tieneOtrasCondiciones ?? false)
        _buildCompactInfoItem(
          Icons.medical_services_outlined,
          'Otras Condiciones',
          client.otrasCondiciones ?? 'No especificado',
        ),
    ];
  }

  // Generate aesthetic history items
  List<Widget> _buildAestheticHistoryItems() {
    return [
      Wrap(
        spacing: AppStyles.spacingL,
        runSpacing: AppStyles.spacingM,
        children: [
          if (client.tieneProcedimientosEsteticosPrevios ?? false)
            _buildCompactInfoItem(
              Icons.spa_outlined,
              'Procedimientos Estéticos',
              client.procedimientosEsteticosPrevios ?? 'No especificado',
            ),
          if (client.tieneCirugias ?? false)
            _buildCompactInfoItem(
              Icons.healing_outlined,
              'Cirugías',
              client.cirugias ?? 'No especificado',
            ),
          if (client.tieneImplantes ?? false)
            _buildCompactInfoItem(
              Icons.biotech_outlined,
              'Implantes',
              client.implantes ?? 'No especificado',
            ),
          if (client.tratamientosActuales != null &&
              client.tratamientosActuales!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.local_hospital_outlined,
              'Tratamientos Actuales',
              client.tratamientosActuales!,
            ),
          if (client.preferenciasTratamiento != null &&
              client.preferenciasTratamiento!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.thumb_up_alt_outlined,
              'Preferencias',
              client.preferenciasTratamiento!,
            ),
        ],
      ),
    ];
  }

  // Generate lifestyle items
  List<Widget> _buildLifestyleItems() {
    final items = <Widget>[];

    // Hábitos como tags
    final habitTags = <Widget>[];
    if (client.fumador ?? false) habitTags.add(_buildConditionTag('Fumador'));
    if (client.consumeAlcohol ?? false)
      habitTags.add(_buildConditionTag('Consume Alcohol'));
    if (client.actividadFisicaRegular ?? false)
      habitTags.add(_buildConditionTag('Actividad Física Regular'));
    if (client.problemasDelSueno ?? false)
      habitTags.add(_buildConditionTag('Problemas de Sueño'));

    if (habitTags.isNotEmpty) {
      items.add(
        Wrap(
          spacing: AppStyles.spacingS,
          runSpacing: AppStyles.spacingS,
          children: habitTags,
        ),
      );
      items.add(const SizedBox(height: AppStyles.spacingM));
    }

    // Wrap para los datos detallados de hábitos
    items.add(
      Wrap(
        spacing: AppStyles.spacingL,
        runSpacing: AppStyles.spacingM,
        children: [
          if (client.alimentacion != null && client.alimentacion!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.restaurant_outlined,
              'Alimentación',
              client.alimentacion!,
            ),
          if (client.sueno != null && client.sueno!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.bedtime_outlined,
              'Sueño',
              client.sueno!,
            ),
          if (client.actividadFisica != null &&
              client.actividadFisica!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.fitness_center_outlined,
              'Actividad Física',
              client.actividadFisica!,
            ),
          if (client.consumoAgua != null && client.consumoAgua!.isNotEmpty)
            _buildCompactInfoItem(
              Icons.water_drop_outlined,
              'Consumo de Agua',
              client.consumoAgua!,
            ),
        ],
      ),
    );

    return items;
  }

  // Generate treatment items
  List<Widget> _buildTreatmentItems() {
    final items = <Widget>[];

    items.add(
      _buildCompactInfoItem(
        Icons.assignment_outlined,
        'Tipo de Tratamiento',
        client.tipoTratamiento!,
      ),
    );

    // Tratamiento Facial
    if (client.tipoTratamiento == 'Facial') {
      items.add(const SizedBox(height: AppStyles.spacingM));
      items.add(_buildSubsectionTitle('Tratamiento Facial'));

      items.add(
        Wrap(
          spacing: AppStyles.spacingL,
          runSpacing: AppStyles.spacingM,
          children: [
            if (client.tipoPiel != null && client.tipoPiel!.isNotEmpty)
              _buildCompactInfoItem(
                Icons.face_outlined,
                'Tipo de Piel',
                client.tipoPiel!,
              ),
            if (client.estadoPiel != null && client.estadoPiel!.isNotEmpty)
              _buildCompactInfoItem(
                Icons.health_and_safety_outlined,
                'Estado de la Piel',
                client.estadoPiel!,
              ),
            if (client.gradoFlacidez != null)
              _buildCompactInfoItem(
                Icons.trending_down_outlined,
                'Grado de Flacidez',
                client.gradoFlacidez!,
              ),
          ],
        ),
      );

      // NUEVO: Diagrama facial
      if (client.facialMarks != null && client.facialMarks!.isNotEmpty) {
        items.add(const SizedBox(height: AppStyles.spacingM));
        items.add(_buildSubsectionTitle('Diagrama Facial'));

        // Tamaño fijo para el diagrama
        final double diagramWidth = 250;
        final double diagramHeight = 300;

        // Calcular identificadores para las marcas
        final Map<int, String> markIdentifiers = {};
        for (int i = 0; i < client.facialMarks!.length; i++) {
          final mark = client.facialMarks![i];
          final typePrefix = _getMarkTypePrefix(mark.type.name);

          // Determinar secuencia (A1, A2, etc.)
          int sequence = 1;
          for (int j = 0; j < i; j++) {
            if (client.facialMarks![j].type == mark.type) {
              sequence++;
            }
          }

          markIdentifiers[i] = "$typePrefix$sequence";
        }

        items.add(
          Container(
            width: diagramWidth,
            height: diagramHeight,
            margin: const EdgeInsets.symmetric(vertical: AppStyles.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              border: Border.all(color: AppStyles.dividerColor),
            ),
            child: Stack(
              children: [
                // Diagrama base con SVG
                SvgPicture.asset(
                  'assets/face_diagram3.svg',
                  width: diagramWidth,
                  height: diagramHeight,
                  fit: BoxFit.contain,
                ),

                // Marcas guardadas con identificadores
                CustomPaint(
                  size: Size(diagramWidth, diagramHeight),
                  painter:
                      FacialMarksPainter(client.facialMarks!, markIdentifiers),
                ),
              ],
            ),
          ),
        );

        // Leyenda de las marcas
        items.add(
          Wrap(
            spacing: AppStyles.spacingM,
            runSpacing: AppStyles.spacingS,
            children: [
              _buildLegendItem('A - Marcas', Colors.purple),
              _buildLegendItem('B - Eritema', Colors.red),
              _buildLegendItem('C - Manchas', Colors.brown),
              _buildLegendItem('D - Lesiones', Colors.orange),
              _buildLegendItem('E - Otros', Colors.blue),
            ],
          ),
        );

        // Lista de marcas con notas
        if (client.facialMarks!
            .any((mark) => mark.notes != null && mark.notes!.isNotEmpty)) {
          items.add(const SizedBox(height: AppStyles.spacingM));
          items.add(_buildSubsectionTitle('Notas del Diagrama'));

          for (int i = 0; i < client.facialMarks!.length; i++) {
            final mark = client.facialMarks![i];
            if (mark.notes != null && mark.notes!.isNotEmpty) {
              items.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppStyles.spacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 4, right: 8),
                        decoration: BoxDecoration(
                          color: mark.getDisplayColor().withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: mark.getDisplayColor()),
                        ),
                        child: Center(
                          child: Text(
                            markIdentifiers[i] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: mark.getDisplayColor(),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          mark.notes ?? '',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppStyles.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }
      }
    }

    // Tratamiento Corporal
    if (client.tipoTratamiento == 'Corporal') {
      // Sección de Medidas
      items.add(const SizedBox(height: AppStyles.spacingM));
      items.add(_buildSubsectionTitle('Medidas (cm)'));

      // Primera fila: Abdomen Alto y Bajo
      if ((client.abdomenAlto != null && client.abdomenAlto!.isNotEmpty) ||
          (client.abdomenBajo != null && client.abdomenBajo!.isNotEmpty)) {
        items.add(
          Row(
            children: [
              if (client.abdomenAlto != null && client.abdomenAlto!.isNotEmpty)
                Expanded(
                  child:
                      _buildCompactInfoRow('Abdomen Alto', client.abdomenAlto!),
                ),
              if (client.abdomenBajo != null && client.abdomenBajo!.isNotEmpty)
                Expanded(
                  child:
                      _buildCompactInfoRow('Abdomen Bajo', client.abdomenBajo!),
                ),
            ],
          ),
        );
      }

      // Segunda fila: Cintura y Espalda
      if ((client.cintura != null && client.cintura!.isNotEmpty) ||
          (client.espalda != null && client.espalda!.isNotEmpty)) {
        items.add(
          Row(
            children: [
              if (client.cintura != null && client.cintura!.isNotEmpty)
                Expanded(
                  child: _buildCompactInfoRow('Cintura', client.cintura!),
                ),
              if (client.espalda != null && client.espalda!.isNotEmpty)
                Expanded(
                  child: _buildCompactInfoRow('Espalda', client.espalda!),
                ),
            ],
          ),
        );
      }

      // Tercera fila: Brazos
      if ((client.brazoIzq != null && client.brazoIzq!.isNotEmpty) ||
          (client.brazoDerecho != null && client.brazoDerecho!.isNotEmpty)) {
        items.add(
          Row(
            children: [
              if (client.brazoIzq != null && client.brazoIzq!.isNotEmpty)
                Expanded(
                  child:
                      _buildCompactInfoRow('Brazo Izquierdo', client.brazoIzq!),
                ),
              if (client.brazoDerecho != null &&
                  client.brazoDerecho!.isNotEmpty)
                Expanded(
                  child: _buildCompactInfoRow(
                      'Brazo Derecho', client.brazoDerecho!),
                ),
            ],
          ),
        );
      }

      // Sección de Antropología
      items.add(const SizedBox(height: AppStyles.spacingM));
      items.add(_buildSubsectionTitle('Antropología'));

      // Fila de Peso y Altura
      if ((client.pesoActual != null && client.pesoActual!.isNotEmpty) ||
          (client.altura != null && client.altura!.isNotEmpty)) {
        items.add(
          Row(
            children: [
              if (client.pesoActual != null && client.pesoActual!.isNotEmpty)
                Expanded(
                  child: _buildCompactInfoRow('Peso (kg)', client.pesoActual!),
                ),
              if (client.altura != null && client.altura!.isNotEmpty)
                Expanded(
                  child: _buildCompactInfoRow('Altura (cm)', client.altura!),
                ),
            ],
          ),
        );
      }

      // IMC y Clasificación
      if (client.imc != null && client.nivelObesidad != null) {
        items.add(
          Container(
            margin: const EdgeInsets.only(top: AppStyles.spacingS),
            padding: const EdgeInsets.all(AppStyles.spacingS),
            decoration: BoxDecoration(
              color: AppStyles.surfaceColor,
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMC: ${client.imc}',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Clasificación: ${client.nivelObesidad}',
                  style: AppStyles.bodyMedium,
                ),
              ],
            ),
          ),
        );
      }

      // Sección de Patologías
      items.add(const SizedBox(height: AppStyles.spacingM));
      items.add(_buildSubsectionTitle('Patologías'));

      // Celulitis
      if (client.tieneCelulitis ?? false) {
        items.add(
          _buildCompactInfoItem(
            Icons.texture_outlined,
            'Celulitis',
            'Sí${client.gradoCelulitis != null ? ' - ${client.gradoCelulitis}' : ''}',
          ),
        );

        if (client.lugarCelulitis != null &&
            client.lugarCelulitis!.isNotEmpty) {
          items.add(
            _buildCompactInfoItem(
              Icons.place_outlined,
              'Ubicación de Celulitis',
              client.lugarCelulitis!,
            ),
          );
        }
      }

      // Estrías
      if (client.tieneEstrias ?? false) {
        items.add(
          _buildCompactInfoItem(
            Icons.linear_scale_outlined,
            'Estrías',
            'Sí',
          ),
        );

        if (client.colorEstrias != null && client.colorEstrias!.isNotEmpty) {
          items.add(
            _buildCompactInfoItem(
              Icons.color_lens_outlined,
              'Color de Estrías',
              client.colorEstrias!,
            ),
          );
        }

        if (client.tiempoEstrias != null && client.tiempoEstrias!.isNotEmpty) {
          items.add(
            _buildCompactInfoItem(
              Icons.access_time_outlined,
              'Tiempo de Estrías',
              client.tiempoEstrias!,
            ),
          );
        }
      }
    }

    // Tratamiento de Bronceado
    if (client.tipoTratamiento == 'Bronceado') {
      items.add(const SizedBox(height: AppStyles.spacingM));
      items.add(_buildSubsectionTitle('Tratamiento de Bronceado'));

      items.add(
        Wrap(
          spacing: AppStyles.spacingL,
          runSpacing: AppStyles.spacingM,
          children: [
            if (client.escalaGlasgow != null)
              _buildCompactInfoItem(
                Icons.scale_outlined,
                'Escala de Glasgow',
                client.escalaGlasgow!,
              ),
            if (client.escalaFitzpatrick != null)
              _buildCompactInfoItem(
                Icons.palette_outlined,
                'Escala Fitzpatrick',
                client.escalaFitzpatrick!,
              ),
          ],
        ),
      );
    }

    return items;
  }

  // Helper to build subsection title
  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacingS),
      child: Text(
        title,
        style: AppStyles.labelMedium.copyWith(
          color: AppStyles.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Compact info item for two-column layout
  Widget _buildCompactInfoItem(IconData icon, String label, String value,
      {Color? iconColor}) {
    return Container(
      width: 200, // Fixed width for consistent columns
      margin: const EdgeInsets.only(bottom: AppStyles.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor ?? AppStyles.primaryColor,
          ),
          const SizedBox(width: AppStyles.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.labelSmall,
                ),
                const SizedBox(height: AppStyles.spacingXS),
                Text(
                  value,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Original info row style for backward compatibility
  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? AppStyles.primaryColor,
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.labelMedium,
                ),
                const SizedBox(height: AppStyles.spacingXS),
                Text(
                  value,
                  style: AppStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Compact row for measurements
  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppStyles.spacingS, right: AppStyles.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyles.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Medical condition tag widget
  Widget _buildConditionTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingM,
        vertical: AppStyles.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      child: Text(
        label,
        style: AppStyles.bodySmall.copyWith(
          color: AppStyles.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // NUEVO: Método para construir elementos de la leyenda
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppStyles.spacingXS),
        Text(
          text,
          style: AppStyles.bodySmall,
        ),
      ],
    );
  }
}

String _getMarkTypePrefix(String markType) {
  switch (markType) {
    case 'marca':
      return 'A';
    case 'eritema':
      return 'B';
    case 'mancha':
      return 'C';
    case 'lesion':
      return 'D';
    case 'otro':
      return 'E';
    default:
      return '?'; // O maneja los tipos desconocidos como necesites
  }
}

// Client Appointments Tab
class ClientAppointmentsTab extends StatefulWidget {
  final String clientId;

  const ClientAppointmentsTab({required this.clientId});

  @override
  _ClientAppointmentsTabState createState() => _ClientAppointmentsTabState();
}

class _ClientAppointmentsTabState extends State<ClientAppointmentsTab> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final appointments =
          await dbService.getClientAppointments(widget.clientId);

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar citas: ${e.toString()}'),
          backgroundColor: AppStyles.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppStyles.primaryColor,
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 48,
              color: AppStyles.secondaryTextColor,
            ),
            const SizedBox(height: AppStyles.spacingM),
            Text(
              'No hay citas para este cliente',
              style: AppStyles.bodyLarge.copyWith(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create appointment
                Navigator.pushNamed(
                  context,
                  '/new-appointment',
                  arguments: {'clientId': widget.clientId},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Cita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingL,
                  vertical: AppStyles.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppStyles.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return AppointmentListTile(
            appointment: appointment,
            showClient: false,
          );
        },
      ),
    );
  }
}

// AppointmentListTile Widget
class AppointmentListTile extends StatefulWidget {
  final AppointmentModel appointment;
  final bool showClient;

  const AppointmentListTile({
    required this.appointment,
    this.showClient = true,
  });

  @override
  _AppointmentListTileState createState() => _AppointmentListTileState();
}

class _AppointmentListTileState extends State<AppointmentListTile> {
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

      if (widget.showClient) {
        _client = await dbService.getUser(widget.appointment.clientId);
      }

      _therapist = await dbService.getUser(widget.appointment.employeeId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor() {
    switch (widget.appointment.status) {
      case AppointmentStatus.scheduled:
        return AppStyles.primaryColor;
      case AppointmentStatus.completed_unpaid:
        return AppStyles.warningColor; // Color para pendiente de cobro
      case AppointmentStatus.completed_paid:
        return AppStyles.successColor; // Verde para pagada
      case AppointmentStatus.cancelled:
        return AppStyles.errorColor;
    }
  }

  String _getStatusText() {
    switch (widget.appointment.status) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.completed_unpaid:
        return 'Completada - Pendiente cobro';
      case AppointmentStatus.completed_paid:
        return 'Completada - Pagada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
        padding: const EdgeInsets.all(AppStyles.spacingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          boxShadow: AppStyles.shadowSmall,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppStyles.primaryColor,
              ),
            ),
            SizedBox(width: AppStyles.spacingM),
            Text('Cargando...'),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: AppStyles.shadowSmall,
        border: Border.all(
          color: _getStatusColor().withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/appointment-details',
              arguments: {'appointmentId': widget.appointment.id},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            child: Row(
              children: [
                // Date or Client Avatar
                widget.showClient
                    ? ClientAvatar(
                        photoUrl: _client?.photoUrl,
                        name: _client?.name,
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor().withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('dd').format(widget.appointment.date),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(width: AppStyles.spacingM),

                // Appointment details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.showClient
                            ? (_client?.fullName ?? 'Cliente')
                            : DateFormat('EEEE, d MMMM', 'es')
                                .format(widget.appointment.date),
                        style: AppStyles.headingSmall,
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppStyles.secondaryTextColor,
                          ),
                          const SizedBox(width: AppStyles.spacingXS),
                          Text(
                            widget.appointment.startTime.format(context),
                            style: AppStyles.bodySmall,
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          const Icon(
                            Icons.spa_outlined,
                            size: 14,
                            color: AppStyles.secondaryTextColor,
                          ),
                          const SizedBox(width: AppStyles.spacingXS),
                          Expanded(
                            child: Text(
                              widget.appointment.treatmentType,
                              style: AppStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppStyles.secondaryTextColor,
                          ),
                          const SizedBox(width: AppStyles.spacingXS),
                          Text(
                            'Terapeuta: ${_therapist?.fullName ?? 'Desconocido'}',
                            style: AppStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacingM,
                    vertical: AppStyles.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: AppStyles.labelSmall.copyWith(
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Client Payments Tab
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
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final transactions =
          await dbService.getClientTransactions(widget.clientId);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar transacciones: ${e.toString()}'),
          backgroundColor: AppStyles.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppStyles.primaryColor,
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: AppStyles.secondaryTextColor,
            ),
            const SizedBox(height: AppStyles.spacingM),
            Text(
              'No hay transacciones para este cliente',
              style: AppStyles.bodyLarge.copyWith(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create transaction
                Navigator.pushNamed(
                  context,
                  '/new-transaction',
                  arguments: {'clientId': widget.clientId},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Transacción'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingL,
                  vertical: AppStyles.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: AppStyles.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return TransactionListTile(transaction: transaction);
        },
      ),
    );
  }
}

// TransactionListTile Widget
class TransactionListTile extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionListTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPayment = transaction.type == TransactionType.payment;
    final color = isPayment ? AppStyles.successColor : AppStyles.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: AppStyles.shadowSmall,
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          onTap: () {
            // View transaction details
          },
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            child: Row(
              children: [
                // Transaction icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    isPayment ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),

                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: AppStyles.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Text(
                        DateFormat('dd/MM/yyyy - HH:mm')
                            .format(transaction.date),
                        style: AppStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: AppStyles.headingSmall.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
