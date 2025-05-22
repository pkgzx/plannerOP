import 'package:flutter/material.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/services/programmings/programmings.dart';

class ProgrammingsProvider extends ChangeNotifier {
  final ProgrammingsService _programmingsService = ProgrammingsService();
  List<Programming> _programmings = [];
  bool _isLoading = false;
  String? _error;

  List<Programming> get programmings => _programmings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProgrammingsByDate(
      String date, BuildContext context) async {
    // Usar Future.microtask para ejecutar notifyListeners() después de que termine la construcción
    Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final programmings =
          await _programmingsService.getProgrammingsByDate(date, context);

      // Asegurarse de que estemos fuera del ciclo de construcción
      _programmings = programmings;

      // Usar Future.microtask también para la actualización final
      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Error al obtener programaciones: $e';

      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }
}
