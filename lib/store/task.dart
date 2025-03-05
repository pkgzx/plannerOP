import 'package:flutter/material.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/services/task/task.dart';

class TasksProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar las tareas desde el API
  Future<void> loadTasks(BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _taskService.fetchTasks(context);

      if (result.isSuccess) {
        _tasks = result.tasks;
      } else {
        _error = result.errorMessage ?? 'Error al cargar tareas';
      }
    } catch (e) {
      _error = 'Error inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
