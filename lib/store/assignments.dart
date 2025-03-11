import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/dto/assignment/createAssigment.dart';
import 'package:plannerop/services/assignments/assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentsProvider extends ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();
  List<Assignment> _assignments = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 30);

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Assignment> get pendingAssignments =>
      _assignments.where((a) => a.status == 'PENDING').toList();

  List<Assignment> get inProgressAssignments =>
      _assignments.where((a) => a.status == 'INPROGRESS').toList();

  List<Assignment> get completedAssignments =>
      _assignments.where((a) => a.status == 'COMPLETED').toList();

  AssignmentsProvider() {
    _startRefreshTimer();
  }

  void changeIsLoadingOff() {
    debugPrint('Cambiando isLoading a false');
    _isLoading = false;
    notifyListeners();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_lastContext != null) {
        refreshActiveAssignments(_lastContext!);
      }
    });
  }

  BuildContext? _lastContext;

  // Método para refrescar solo asignaciones activas
  Future<void> refreshActiveAssignments(BuildContext context) async {
    _lastContext = context;

    try {
      // Refrescar solo asignaciones activas y pendientes
      final updatedAssignments = await _assignmentService
          .fetchAssignmentsByStatus(context, ['INPROGRESS', 'PENDING']);

      if (updatedAssignments.isNotEmpty) {
        // Actualizar lista existente
        _updateAssignmentsList(updatedAssignments);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al refrescar asignaciones activas: $e');
      // No mostrar error para refrescos silenciosos
    }
  }

// No olvidar añadir dispose para limpiar el temporizador
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadAssignments(BuildContext context) async {
    _isLoading = true;
    _error = null; // Resetear error previo
    notifyListeners();

    try {
      debugPrint('Intentando cargar asignaciones desde API...');
      final assignments = await _assignmentService.fetchAssignments(context);

      // Limpiar lista existente
      _assignments.clear();

      // Añadir nuevas asignaciones
      _assignments.addAll(assignments);

      if (_assignments.isEmpty) {
        debugPrint('No se encontraron asignaciones en la API.');
        _error = 'No se encontraron asignaciones disponibles.';
      } else {
        debugPrint(
            'Asignaciones cargadas exitosamente: ${_assignments.length}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error al cargar asignaciones: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Error al cargar asignaciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = json.encode(
          _assignments.map((assignment) => assignment.toJson()).toList());
      await prefs.setString('assignments', assignmentsJson);
    } catch (e) {
      debugPrint('Error saving assignments: $e');
    }
  }

// Método actualizado para agregar asignación con todos los campos
  Future<bool> addAssignment({
    required List<Worker> workers,
    required String area,
    required int areaId,
    required String task,
    required int taskId,
    required DateTime date,
    required String time,
    required int zoneId,
    required int userId,
    required int clientId,
    String? clientName,
    DateTime? endDate,
    String? endTime,
    String? motorship,
    BuildContext? context, // Necesario para el token
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAssignment = Assignment(
        workers: workers,
        area: area,
        task: task,
        date: date,
        time: time,
        zone: zoneId,
        status: 'PENDING',
        endDate: endDate,
        endTime: endTime,
        motorship: motorship,
        userId: userId,
        areaId: areaId,
        taskId: taskId,
        clientId: clientId,
      );

      // Si tenemos contexto, intentamos enviar al backend
      CreateassigmentDto response = CreateassigmentDto(id: 0, isSuccess: false);
      if (context != null) {
        response =
            await _assignmentService.createAssignment(newAssignment, context);
        newAssignment.id = response.id;
      }

      // Si se envió con éxito al backend (o no hay contexto), guardamos localmente
      if (response.isSuccess) {
        _assignments.add(newAssignment);
        await _saveAssignments();
      } else {
        _error = "Error al crear la asignación en el servidor";
      }

      _isLoading = false;
      notifyListeners();
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error al agregar asignación: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateAssignmentStatus(
      int id, String status, BuildContext context) async {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final currentAssignment = _assignments[index];
      _assignments[index] = Assignment(
        id: currentAssignment.id,
        workers: currentAssignment.workers,
        area: currentAssignment.area,
        task: currentAssignment.task,
        date: currentAssignment.date,
        time: currentAssignment.time,
        zone: currentAssignment.zone,
        status: status,
        endDate: currentAssignment.endDate,
        endTime: currentAssignment.endTime,
        motorship: currentAssignment.motorship,
        userId: currentAssignment.userId,
        areaId: currentAssignment.areaId,
        taskId: currentAssignment.taskId,
        clientId: currentAssignment.clientId,
      );

      debugPrint('Actualizando estado de la asignación en el backend...');

      await _assignmentService.updateStatusAssignment(id, status, context);

      await _saveAssignments();
      notifyListeners();
    }
  }

  Future<void> updateAssignmentEndTime(int id, String endTime) async {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final currentAssignment = _assignments[index];
      _assignments[index] = Assignment(
        id: currentAssignment.id,
        workers: currentAssignment.workers,
        area: currentAssignment.area,
        task: currentAssignment.task,
        date: currentAssignment.date,
        time: currentAssignment.time,
        zone: currentAssignment.zone,
        status: currentAssignment.status,
        endDate: currentAssignment.endDate,
        endTime: endTime,
        motorship: currentAssignment.motorship,
        userId: currentAssignment.userId,
        areaId: currentAssignment.areaId,
        taskId: currentAssignment.taskId,
        clientId: currentAssignment.clientId,
      );
      await _saveAssignments();
      notifyListeners();
    }
  }

  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((a) => a.id == id);
    await _saveAssignments();
    notifyListeners();
  }

  Assignment? getAssignmentById(String id) {
    try {
      return _assignments.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Añadir este nuevo método al AssignmentsProvider
  Future<bool> updateAssignment(
      Assignment updatedAssignment, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Actualizar en el backend
      final success = await _assignmentService.updateAssignmentToComplete(
          updatedAssignment, context);

      if (success) {
        // Actualizar en la lista local
        final index =
            _assignments.indexWhere((a) => a.id == updatedAssignment.id);
        if (index >= 0) {
          _assignments[index] = updatedAssignment;
        }
      } else {
        _error = "Error al actualizar la asignación en el servidor";
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error en updateAssignment: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

// Añadir a la clase AssignmentsProvider
  Future<void> loadAssignmentsWithPriority(BuildContext context) async {
    // No establecer isLoading = true si ya hay datos para evitar reconstrucciones innecesarias
    final hasExistingData = _assignments.isNotEmpty;

    if (!hasExistingData) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Primera fase: Cargar asignaciones activas y pendientes (alta prioridad)
      final highPriorityAssignments = await _assignmentService
          .fetchAssignmentsByStatus(context, ['INPROGRESS', 'PENDING']);

      // Actualizar primero las asignaciones de alta prioridad
      if (highPriorityAssignments.isNotEmpty) {
        // Mantener asignaciones completadas y añadir/actualizar las de alta prioridad
        final completedAssignments =
            _assignments.where((a) => a.status == 'COMPLETED').toList();

        // Actualizar asignaciones actuales
        _updateAssignmentsList(highPriorityAssignments);

        // Notificar cambios para actualizar la UI inmediatamente
        if (!hasExistingData) {
          _isLoading = false;
          notifyListeners();
        }
      }

      // Segunda fase: Cargar asignaciones completadas (baja prioridad) en segundo plano
      _loadCompletedAssignmentsInBackground(context);
    } catch (e) {
      debugPrint('Error al cargar asignaciones prioritarias: $e');
      _error = 'Error al cargar asignaciones: $e';

      if (!hasExistingData) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

// Método auxiliar para cargar asignaciones completadas en segundo plano
  Future<void> _loadCompletedAssignmentsInBackground(
      BuildContext context) async {
    try {
      final completedAssignments = await _assignmentService
          .fetchAssignmentsByStatus(context, ['COMPLETED']);

      if (completedAssignments.isNotEmpty) {
        // Actualizar solo las asignaciones completadas
        _updateAssignmentsList(completedAssignments);
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          'Error al cargar asignaciones completadas en segundo plano: $e');
      // No establecer error ni notificar, ya que es carga en segundo plano
    }
  }

// Método para actualizar la lista de asignaciones eficientemente
  void _updateAssignmentsList(List<Assignment> newAssignments) {
    for (var newAssignment in newAssignments) {
      final index = _assignments.indexWhere((a) => a.id == newAssignment.id);
      if (index >= 0) {
        // Actualizar asignación existente
        _assignments[index] = newAssignment;
      } else {
        // Añadir nueva asignación
        _assignments.add(newAssignment);
      }
    }
  }

  // Metodo para pasar a completado una asignación
  Future<bool> completeAssignment(
      int id, DateTime endDate, String endTime, BuildContext context) async {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final currentAssignment = _assignments[index];
      _assignments[index] = Assignment(
        id: currentAssignment.id,
        workers: currentAssignment.workers,
        area: currentAssignment.area,
        task: currentAssignment.task,
        date: currentAssignment.date,
        time: currentAssignment.time,
        zone: currentAssignment.zone,
        status: 'COMPLETED',
        endDate: currentAssignment.endDate ?? endDate,
        endTime: currentAssignment.endTime ?? endTime,
        motorship: currentAssignment.motorship,
        userId: currentAssignment.userId,
        areaId: currentAssignment.areaId,
        taskId: currentAssignment.taskId,
        clientId: currentAssignment.clientId,
      );
      notifyListeners();
    }

    // Actualizar en el backend
    return await _assignmentService.completeAssigment(
        id, 'COMPLETED', endDate, endTime, context);
  }
}
