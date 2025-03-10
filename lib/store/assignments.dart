import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/services/assignments/assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentsProvider extends ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();
  List<Assignment> _assignments = [];
  bool _isLoading = false;
  String? _error;

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Assignment> get pendingAssignments =>
      _assignments.where((a) => a.status == 'PENDING').toList();

  List<Assignment> get inProgressAssignments =>
      _assignments.where((a) => a.status == 'IN_PROGRESS').toList();

  List<Assignment> get completedAssignments =>
      _assignments.where((a) => a.status == 'COMPLETED').toList();

  AssignmentsProvider() {}

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
      bool success = true;
      if (context != null) {
        success =
            await _assignmentService.createAssignment(newAssignment, context);
      }

      // Si se envió con éxito al backend (o no hay contexto), guardamos localmente
      if (success) {
        _assignments.add(newAssignment);
        await _saveAssignments();
      } else {
        _error = "Error al crear la asignación en el servidor";
      }

      _isLoading = false;
      notifyListeners();
      return success;
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
}
