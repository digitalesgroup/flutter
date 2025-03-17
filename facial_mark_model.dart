//lib/models/facial_mar_model.dart

import 'package:flutter/material.dart';

enum FacialMarkType {
  marca, // A
  eritema, // B
  mancha, // C
  lesion, // D
  otro, // E
}

enum FacialMarkShape {
  punto,
  circulo,
  area,
}

class FacialMark {
  final FacialMarkType type;
  final FacialMarkShape shape;
  final double x;
  final double y;
  final double? radius; // Para círculos
  final List<Offset>? points; // Para áreas irregulares
  final String? notes;

  FacialMark({
    required this.type,
    required this.shape,
    required this.x,
    required this.y,
    this.radius,
    this.points,
    this.notes,
  });

  // Para conversión a/desde JSON
  Map<String, dynamic> toJson() {
    // Convertir los puntos a un formato serializable si existen
    List<Map<String, double>>? serializedPoints;
    if (points != null) {
      serializedPoints = points!
          .map((point) => {
                'x': point.dx,
                'y': point.dy,
              })
          .toList();
    }

    return {
      'type': type.index,
      'shape': shape.index,
      'x': x,
      'y': y,
      'radius': radius,
      'points': serializedPoints,
      'notes': notes,
    };
  }

  factory FacialMark.fromJson(Map<String, dynamic> json) {
    // Reconstruir los puntos si existen
    List<Offset>? deserializedPoints;
    if (json['points'] != null) {
      deserializedPoints = (json['points'] as List)
          .map((pointJson) => Offset(
                pointJson['x'] as double,
                pointJson['y'] as double,
              ))
          .toList();
    }

    return FacialMark(
      type: FacialMarkType.values[json['type'] as int],
      shape: FacialMarkShape.values[json['shape'] as int],
      x: json['x'] as double,
      y: json['y'] as double,
      radius: json['radius'] as double?,
      points: deserializedPoints,
      notes: json['notes'] as String?,
    );
  }

  // Método para obtener color basado en el tipo
  Color getDisplayColor() {
    switch (type) {
      case FacialMarkType.marca:
        return Colors.purple;
      case FacialMarkType.eritema:
        return Colors.red;
      case FacialMarkType.mancha:
        return Colors.brown;
      case FacialMarkType.lesion:
        return Colors.orange;
      case FacialMarkType.otro:
        return Colors.blue;
    }
  }

  // Nombre legible para el tipo
  String get typeName {
    switch (type) {
      case FacialMarkType.marca:
        return 'Marca';
      case FacialMarkType.eritema:
        return 'Eritema';
      case FacialMarkType.mancha:
        return 'Mancha';
      case FacialMarkType.lesion:
        return 'Lesión';
      case FacialMarkType.otro:
        return 'Otro';
    }
  }
}
