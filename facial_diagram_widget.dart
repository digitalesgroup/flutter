import 'package:flutter/material.dart';
import '../models/facial_mark_model.dart';
import '../painters/facial_diagram_painter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FacialDiagramWidget extends StatefulWidget {
  final List<FacialMark> marks;
  final Function(List<FacialMark>) onMarksChanged;
  final double width;
  final double height;

  const FacialDiagramWidget({
    Key? key,
    required this.marks,
    required this.onMarksChanged,
    this.width = 300,
    this.height = 400,
  }) : super(key: key);

  @override
  _FacialDiagramWidgetState createState() => _FacialDiagramWidgetState();
}

class _FacialDiagramWidgetState extends State<FacialDiagramWidget> {
  FacialMarkType selectedType = FacialMarkType.marca;
  FacialMarkShape selectedShape = FacialMarkShape.circulo;

  // Variables para el dibujo temporal
  List<Offset>? _currentPoints;
  Offset? _startPoint;
  double? _currentRadius;

  // Para notas
  final TextEditingController _notesController = TextEditingController();

  // Global key para obtener la posición exacta del widget
  final GlobalKey _diagramKey = GlobalKey();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Nuevo: Método para calcular identificadores para cada marca
  Map<int, String> _calculateMarkIdentifiers() {
    final Map<int, String> identifiers = {};
    final Map<FacialMarkType, int> typeCounters = {};

    for (int i = 0; i < widget.marks.length; i++) {
      final mark = widget.marks[i];
      final typePrefix = _getTypePrefix(mark.type);

      // Incrementar el contador para este tipo
      typeCounters[mark.type] = (typeCounters[mark.type] ?? 0) + 1;
      final sequence = typeCounters[mark.type]!;

      // Crear el identificador
      identifiers[i] = "$typePrefix$sequence";
    }

    return identifiers;
  }

  // Nuevo: Método para obtener el prefijo del tipo
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

  @override
  Widget build(BuildContext context) {
    // Nuevo: Calculamos los identificadores para cada marca
    final Map<int, String> markIdentifiers = _calculateMarkIdentifiers();

    return Column(
      children: [
        // Herramientas de selección
        _buildToolbar(),

        SizedBox(height: 16),

        // Área del diagrama con tamaño fijo
        Container(
          key: _diagramKey,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: Stack(
              children: [
                // Diagrama base
                SvgPicture.asset(
                  'assets/face_diagram3.svg',
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.contain,
                ),

                // Marcas existentes (Modificado: pasamos los identificadores)
                CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: FacialMarksPainter(widget.marks, markIdentifiers),
                ),

                // Dibujo actual (si está dibujando)
                if (_isDrawing)
                  CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: CurrentMarkPainter(
                      startPoint: _startPoint!,
                      currentPoint: _currentPoints?.last,
                      radius: _currentRadius,
                      points: _currentPoints,
                      shape: selectedShape,
                      color: _getColorForType(selectedType),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Lista de marcas con opción para eliminar (Modificado: pasamos los identificadores)
        _buildMarksList(markIdentifiers),
      ],
    );
  }

  bool get _isDrawing =>
      _startPoint != null &&
      (selectedShape != FacialMarkShape.area || _currentPoints != null);

  Widget _buildToolbar() {
    return Column(
      children: [
        // Selector de tipo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTypeButton(FacialMarkType.marca, 'A - Marcas'),
            _buildTypeButton(FacialMarkType.eritema, 'B - Eritema'),
            _buildTypeButton(FacialMarkType.mancha, 'C - Manchas'),
            _buildTypeButton(FacialMarkType.lesion, 'D - Lesiones'),
            _buildTypeButton(FacialMarkType.otro, 'E - Otros'),
          ],
        ),

        SizedBox(height: 8),

        // Selector de forma
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShapeButton(FacialMarkShape.punto, 'Punto', Icons.circle),
            SizedBox(width: 16),
            _buildShapeButton(
                FacialMarkShape.circulo, 'Círculo', Icons.circle_outlined),
            SizedBox(width: 16),
            _buildShapeButton(FacialMarkShape.area, 'Área', Icons.gesture),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(FacialMarkType type, String label) {
    bool isSelected = selectedType == type;
    Color typeColor = _getColorForType(type);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? typeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? typeColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? typeColor : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildShapeButton(
      FacialMarkShape shape, String tooltip, IconData icon) {
    bool isSelected = selectedShape == shape;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedShape = shape;
          });
        },
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.grey.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Modificado: Añadido parámetro para los identificadores
  Widget _buildMarksList(Map<int, String> identifiers) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: widget.marks.isEmpty
          ? Center(
              child: Text(
                  'No hay marcas faciales. Dibuja en el diagrama para añadir.'),
            )
          : ListView.builder(
              itemCount: widget.marks.length,
              itemBuilder: (context, index) {
                final mark = widget.marks[index];
                final markId = identifiers[index] ?? '';

                return ListTile(
                  dense: true,
                  // Nuevo: Círculo con el identificador como leading
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
                  title: Text(
                    '${mark.typeName} - ${_getShapeName(mark.shape)}',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: mark.notes != null && mark.notes!.isNotEmpty
                      ? Text(
                          mark.notes!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        )
                      : null,
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      _deleteMark(index);
                    },
                  ),
                  onTap: () {
                    // Modificado: Pasamos el identificador
                    _showMarkDetails(mark, index, markId);
                  },
                );
              },
            ),
    );
  }

  Offset _getRelativePosition(Offset globalPosition) {
    final RenderBox box =
        _diagramKey.currentContext?.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(globalPosition);

    // Asegurarse de que las coordenadas están dentro de los límites del diagrama
    double x = localPosition.dx.clamp(0.0, widget.width) / widget.width;
    double y = localPosition.dy.clamp(0.0, widget.height) / widget.height;

    return Offset(x, y);
  }

  void _handlePanStart(DragStartDetails details) {
    final Offset relativePosition =
        _getRelativePosition(details.globalPosition);

    setState(() {
      _startPoint = relativePosition;

      if (selectedShape == FacialMarkShape.area) {
        _currentPoints = [relativePosition];
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_startPoint == null) return;

    final Offset relativePosition =
        _getRelativePosition(details.globalPosition);

    setState(() {
      if (selectedShape == FacialMarkShape.circulo) {
        // Calcular la distancia entre el punto inicial y el actual
        final double dx = relativePosition.dx - _startPoint!.dx;
        final double dy = relativePosition.dy - _startPoint!.dy;
        _currentRadius = (dx * dx + dy * dy);
      } else if (selectedShape == FacialMarkShape.area) {
        // Añadir el punto al path
        _currentPoints!.add(relativePosition);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startPoint == null) return;

    // Preguntar por notas
    _askForNotesAndAddMark();
  }

  void _askForNotesAndAddMark() {
    _notesController.clear();

    // Nuevo: Calcular el ID que tendrá la nueva marca
    final newMarkId = _getNextMarkId(selectedType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            // Nuevo: Mostrar el identificador en el título
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getColorForType(selectedType).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getColorForType(selectedType)),
              ),
              child: Text(
                newMarkId,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getColorForType(selectedType),
                ),
              ),
            ),
            SizedBox(width: 10),
            Text('Añadir Notas (Opcional)'),
          ],
        ),
        content: TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Escribe notas sobre esta marca',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addCurrentMark(null);
            },
            child: Text('Omitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addCurrentMark(_notesController.text);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Nuevo: Método para obtener el siguiente ID de marca
  String _getNextMarkId(FacialMarkType type) {
    final typePrefix = _getTypePrefix(type);
    int count = 0;

    // Contar marcas existentes de este tipo
    for (final mark in widget.marks) {
      if (mark.type == type) {
        count++;
      }
    }

    // El nuevo ID será el siguiente número
    return "$typePrefix${count + 1}";
  }

  void _addCurrentMark(String? notes) {
    if (_startPoint == null) return;

    final newMark = FacialMark(
      type: selectedType,
      shape: selectedShape,
      x: _startPoint!.dx,
      y: _startPoint!.dy,
      radius: _currentRadius,
      points: selectedShape == FacialMarkShape.area
          ? List.from(_currentPoints!)
          : null,
      notes: notes,
    );

    final updatedMarks = List<FacialMark>.from(widget.marks)..add(newMark);
    widget.onMarksChanged(updatedMarks);

    setState(() {
      _startPoint = null;
      _currentPoints = null;
      _currentRadius = null;
    });
  }

  void _deleteMark(int index) {
    if (index < 0 || index >= widget.marks.length) return;

    final updatedMarks = List<FacialMark>.from(widget.marks);
    updatedMarks.removeAt(index);
    widget.onMarksChanged(updatedMarks);
  }

  // Modificado: Añadido parámetro para el identificador
  void _showMarkDetails(FacialMark mark, int index, String markId) {
    _notesController.text = mark.notes ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            // Nuevo: Mostrar el identificador en el título
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
              controller: _notesController,
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
                notes: _notesController.text,
              );

              final updatedMarks = List<FacialMark>.from(widget.marks);
              updatedMarks[index] = updatedMark;
              widget.onMarksChanged(updatedMarks);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(FacialMarkType type) {
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
        return '';
      case FacialMarkShape.circulo:
        return '';
      case FacialMarkShape.area:
        return '';
    }
  }
}
