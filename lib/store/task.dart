import 'package:flutter/material.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/services/task/task.dart';

class TasksProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _hasBeenLoaded = false;

  // Flag que marca si se ha intentado cargar desde API
  bool _hasAttemptedLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBeenLoaded => _hasBeenLoaded;
  bool get hasAttemptedLoading => _hasAttemptedLoading;

  // Método para cargar tareas solo si es necesario
  Future<void> loadTasksIfNeeded(BuildContext context) async {
    // Si ya están cargadas o se está cargando, no hacer nada
    if (_isLoading || _hasAttemptedLoading) {
      return;
    }

    return loadTasks(context);
  }

  String getTaskNameByIdService(int id) {
    final task = _tasks.firstWhere((task) => task.id == id,
        orElse: () => Task(id: 0, name: ''));
    return task.name;
  }

  // Cargar las tareas desde el API
  Future<void> loadTasks(BuildContext context) async {
    // Si ya está cargando, prevenir múltiples llamadas
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _taskService.fetchTasks(context);
      // Marcar que ya se intentó cargar desde la API
      _hasAttemptedLoading = true;

      if (result.isSuccess) {
        // Incluso si la lista está vacía, la guardamos
        _tasks = result.tasks;
        _hasBeenLoaded = true;
      } else {
        _error = result.errorMessage ?? 'Error al cargar tareas';
        // Si falló, cargar tareas por defecto
        loadDefaultTasks();
      }
    } catch (e) {
      _error = 'Error inesperado: $e';
      // Si hay error, cargar tareas por defecto
      loadDefaultTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para cargar tareas por defecto
  void loadDefaultTasks() {
    // Solo cargar las tareas por defecto si la lista actual está vacía
    if (_tasks.isNotEmpty) return;

    _tasks = [
      Task(id: 1, name: "SERVICIO DE ESTIBAJE"),
      Task(id: 2, name: "SERVICIO DE WINCHERO"),
      Task(id: 3, name: "SERVICIO DE PORTALONERO"),
      Task(id: 4, name: "SERVICIO DE RETIRO"),
      // Añade más tareas predeterminadas según necesites
    ];

    // Marcar como cargadas
    _hasBeenLoaded = true;
  }

  // Lista de nombres de tareas
  List<String> get taskNames => _tasks.map((task) => task.name).toList();

  Task getTaskByName(String name) {
    return _tasks.firstWhere((task) => task.name == name,
        orElse: () => Task(id: 0, name: ''));
  }
}
