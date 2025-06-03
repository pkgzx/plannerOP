import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/services/task/task.dart';

class TasksProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _hasBeenLoaded = false;
  bool _hasAttemptedLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBeenLoaded => _hasBeenLoaded;
  bool get hasAttemptedLoading => _hasAttemptedLoading;

  // Método para cargar tareas solo si es necesario
  Future<void> loadTasksIfNeeded(BuildContext context) async {
    if (_isLoading || _hasAttemptedLoading) {
      return;
    }
    return loadTasks(context);
  }

  // MEJORADO: Método asíncrono con mejor debugging
  Future<String> getTaskNameByIdServiceAsync(
      int id, BuildContext context) async {
    debugPrint('🔍 getTaskNameByIdServiceAsync called with ID: $id');
    debugPrint('   - _hasAttemptedLoading: $_hasAttemptedLoading');
    debugPrint('   - _isLoading: $_isLoading');
    debugPrint('   - _tasks.length: ${_tasks.length}');

    // Si no se han cargado las tareas aún, cargarlas
    if (!_hasAttemptedLoading && !_isLoading) {
      debugPrint('   - Iniciando carga de tareas...');

      // Usar scheduler para cargar después del build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadTasks(context);
      });

      // Esperar a que se inicie la carga
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Esperar a que terminen de cargar con timeout
    int maxWaitCycles = 50; // 5 segundos máximo
    int waitCycle = 0;

    while (_isLoading && waitCycle < maxWaitCycles) {
      debugPrint('   - Esperando carga... ciclo $waitCycle');
      await Future.delayed(const Duration(milliseconds: 100));
      waitCycle++;
    }

    if (waitCycle >= maxWaitCycles) {
      debugPrint('   - ⚠️ Timeout esperando carga de tareas');
      return 'Error: Timeout cargando servicios';
    }

    // Verificar si tenemos tareas cargadas
    debugPrint('   - Tareas disponibles después de la carga: ${_tasks.length}');
    if (_tasks.isEmpty) {
      debugPrint('   - ⚠️ No hay tareas cargadas');
      return 'No hay servicios disponibles';
    }

    // Buscar la tarea
    final task = _tasks.firstWhere(
      (task) => task.id == id,
      orElse: () => Task(id: 0, name: ''),
    );

    debugPrint('   - Tarea encontrada: ${task.id} - "${task.name}"');

    // Debug: Mostrar todas las tareas disponibles si no se encuentra
    if (task.name.isEmpty && id > 0) {
      debugPrint('   - 🔍 Tareas disponibles:');
      for (var t in _tasks.take(10)) {
        // Mostrar solo las primeras 10
        debugPrint('     * ID: ${t.id}, Nombre: "${t.name}"');
      }
      if (_tasks.length > 10) {
        debugPrint('     ... y ${_tasks.length - 10} más');
      }
    }

    return task.name.isNotEmpty ? task.name : 'Servicio ID $id no encontrado';
  }

  // MEJORADO: Cargar las tareas desde el API
  Future<void> loadTasks(BuildContext context) async {
    if (_isLoading) {
      debugPrint('🔄 loadTasks ya está en progreso, saltando...');
      return;
    }

    debugPrint('🔄 Iniciando carga de tareas desde API...');
    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      final result = await _taskService.fetchTasks(context);
      _hasAttemptedLoading = true;

      if (result.isSuccess) {
        _tasks = result.tasks;
        _hasBeenLoaded = true;

        debugPrint('✅ Tareas cargadas exitosamente: ${_tasks.length}');

        // Debug: Mostrar algunas tareas cargadas
        if (_tasks.isNotEmpty) {
          debugPrint('📋 Primeras tareas cargadas:');
          for (var task in _tasks.take(5)) {
            debugPrint('   - ID: ${task.id}, Nombre: "${task.name}"');
          }
          if (_tasks.length > 5) {
            debugPrint('   ... y ${_tasks.length - 5} más');
          }
        }
      } else {
        _error = result.errorMessage ?? 'Error al cargar tareas';
        debugPrint('❌ Error cargando tareas: $_error');
      }
    } catch (e) {
      _error = 'Error inesperado: $e';
      debugPrint('💥 Excepción cargando tareas: $e');
    } finally {
      _isLoading = false;
      debugPrint('🏁 Carga de tareas finalizada. isLoading: $_isLoading');
      _safeNotifyListeners();
    }
  }

  // Método para notificar de forma segura
  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // Lista de nombres de tareas
  List<String> get taskNames => _tasks.map((task) => task.name).toList();

  Task getTaskByName(String name) {
    return _tasks.firstWhere((task) => task.name == name,
        orElse: () => Task(id: 0, name: ''));
  }

  // MEJORADO: Método síncrono con mejor debugging
  String getTaskNameByIdService(int id) {
    final task = _tasks.firstWhere((task) => task.id == id,
        orElse: () => Task(id: 0, name: ''));

    debugPrint(
        '🔍 getTaskNameByIdService: ID=$id, encontrado="${task.name}", total_tareas=${_tasks.length}');

    if (task.name.isEmpty && id > 0) {
      if (_tasks.isEmpty) {
        return 'Cargando servicios...';
      } else {
        return 'Servicio ID $id no encontrado';
      }
    }

    return task.name.isEmpty ? 'Servicio no especificado' : task.name;
  }

  // NUEVO: Método para buscar manualmente una tarea (para debugging)
  void debugSearchTask(int id) {
    debugPrint('🔍 DEBUG: Buscando tarea con ID $id');
    debugPrint('   - Total tareas: ${_tasks.length}');
    debugPrint('   - hasAttemptedLoading: $_hasAttemptedLoading');
    debugPrint('   - isLoading: $_isLoading');

    for (var task in _tasks) {
      if (task.id == id) {
        debugPrint('   - ✅ ENCONTRADA: ID=${task.id}, Nombre="${task.name}"');
        return;
      }
    }

    debugPrint('   - ❌ NO ENCONTRADA');
    debugPrint(
        '   - IDs disponibles: ${_tasks.map((t) => t.id).take(20).toList()}');
  }

  // NUEVO: Método para verificar si existe una tarea
  bool hasTaskWithId(int id) {
    return _tasks.any((task) => task.id == id);
  }
}
