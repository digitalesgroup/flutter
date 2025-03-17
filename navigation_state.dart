// lib/models/navigation_state.dart
import 'package:flutter/foundation.dart';

class NavigationState extends ChangeNotifier {
  // Estado para la navegación principal (dashboard)
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // Estado para la navegación secundaria (detalles)
  String? _currentDetailId;
  String? get currentDetailId => _currentDetailId;

  String _currentDetailType = '';
  String get currentDetailType => _currentDetailType;

  // Para saber si estamos en una vista de detalle
  bool _isInDetailView = false;
  bool get isInDetailView => _isInDetailView;

  // Historial de navegación para poder volver atrás
  final List<Map<String, dynamic>> _navigationHistory = [];

  // Cambia la sección principal
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    // Al cambiar de sección principal, salimos de la vista de detalle
    _isInDetailView = false;
    _currentDetailId = null;
    _currentDetailType = '';
    _navigationHistory.clear();
    notifyListeners();
  }

  // Navega a una vista de detalle
  void navigateToDetail(String detailType, String id) {
    // Guardar el estado actual en el historial si estamos en una vista de detalle
    if (_isInDetailView) {
      _navigationHistory.add({
        'detailType': _currentDetailType,
        'detailId': _currentDetailId,
      });
    }

    _currentDetailType = detailType;
    _currentDetailId = id;
    _isInDetailView = true;
    notifyListeners();
  }

  // Vuelve a la vista anterior
  void goBack() {
    if (_navigationHistory.isEmpty) {
      // Si no hay historial, volvemos a la vista principal
      _isInDetailView = false;
      _currentDetailId = null;
      _currentDetailType = '';
    } else {
      // Recuperamos el último estado del historial
      final lastState = _navigationHistory.removeLast();
      _currentDetailType = lastState['detailType'] ?? '';
      _currentDetailId = lastState['detailId'];
    }
    notifyListeners();
  }
}
