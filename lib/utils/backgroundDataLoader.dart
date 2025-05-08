import 'dart:async';
import 'package:flutter/foundation.dart';

// Añadir esta clase para manejar cargas en segundo plano
class BackgroundDataLoader {
  // Singleton para manejar la carga en segundo plano
  static final BackgroundDataLoader _instance =
      BackgroundDataLoader._internal();
  factory BackgroundDataLoader() => _instance;
  BackgroundDataLoader._internal();

  // Estado de carga para cada tipo de datos
  final Map<String, bool> _isLoading = {};
  final Map<String, bool> _hasLoaded = {};

  // Verificar si algo está cargando
  bool isLoading(String key) => _isLoading[key] ?? false;
  bool hasLoaded(String key) => _hasLoaded[key] ?? false;

  // Método de carga genérico que no depende del contexto del widget
  Future<void> loadData(
      String key, Future<void> Function() loadFunction) async {
    // Si ya está cargando, no hacer nada
    if (_isLoading[key] == true) return;

    _isLoading[key] = true;

    try {
      // Ejecutar la función de carga en una tarea aislada si es posible
      await loadFunction();
      _hasLoaded[key] = true;
    } catch (e) {
      debugPrint('Error cargando $key: $e');
    } finally {
      _isLoading[key] = false;
    }
  }
}
