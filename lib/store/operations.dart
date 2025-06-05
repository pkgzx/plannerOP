import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/dto/operations/createOperation.dart';
import 'package:plannerop/services/operations/operation.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OperationsProvider extends ChangeNotifier {
  final OperationService _operationService = OperationService();
  List<Operation> _assignments = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 30);

  List<Operation> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BuildContext? _lastContext;

  List<Operation> get pendingAssignments =>
      _assignments.where((a) => a.status == 'PENDING').toList();

  List<Operation> get inProgressAssignments =>
      _assignments.where((a) => a.status == 'INPROGRESS').toList();

  List<Operation> get completedAssignments =>
      _assignments.where((a) => a.status == 'COMPLETED').toList();

  AssignmentsProvider() {
    _startRefreshTimer();
  }

  void changeIsLoadingOff() {
    _isLoading = false;
    notifyListeners();
  }

  // Actualizar el método completeGroupOrIndividual para incluir fecha y hora de inicio
  Future<bool> completeGroupOrIndividual(
    Operation assignment,
    List<Worker> workers,
    String groupId,
    DateTime endDate,
    String endTime,
    BuildContext context,
  ) async {
    // debugPrint('Completando grupo/individual: $groupId');

    // Add a timeout to prevent UI from being stuck
    bool hasCompleted = false;
    Timer? timeoutTimer;

    timeoutTimer = Timer(Duration(seconds: 15), () {
      if (!hasCompleted) {
        // debugPrint('Operation timed out - forcing state reset');
        _isLoading = false;
        _error = 'La operación tardó demasiado tiempo. Inténtalo de nuevo.';
        notifyListeners();
      }
    });

    try {
      _error = null;
      notifyListeners();

      // Determinar fecha y hora de inicio según sea grupo o individual
      DateTime startDate;
      String startTime;

      // Si es un grupo específico, buscar sus datos de inicio
      if (groupId != "individual" && !groupId.startsWith("worker_")) {
        // Buscar el grupo por ID
        final group = assignment.groups.firstWhere(
          (g) => g.id == groupId,
          orElse: () =>
              WorkerGroup(workers: [], name: "", id: "", serviceId: 0),
        );

        // Si el grupo tiene fecha y hora de inicio, usarlas
        if (group.startDate != null && group.startTime != null) {
          startDate = DateTime.parse(group.startDate!);
          startTime = group.startTime!;
        } else {
          // Si no tiene, usar los de la operación principal
          startDate = assignment.date;
          startTime = assignment.time;
        }
      } else {
        // Para trabajadores individuales o grupos genéricos, usar los de la operación
        startDate = assignment.date;
        startTime = assignment.time;
      }

      // Obtener IDs de los trabajadores a completar
      final List<int> workerIds = workers.map((w) => w.id).toList();

      // Si es un grupo, usar sus IDs de trabajadores
      var workerIdsToSend = groupId.startsWith("worker_")
          ? [int.parse(groupId.split("_")[1])]
          : workerIds;

      // NUEVA LÓGICA: Verificar si este es el último grupo
      bool isLastGroup = false;
      if (groupId != "individual" && !groupId.startsWith("worker_")) {
        // Contar cuántos grupos quedarían después de completar este
        final remainingGroups =
            assignment.groups.where((g) => g.id != groupId).toList();
        isLastGroup = remainingGroups.isEmpty;
      }

      // Si es el último grupo, completar toda la operación
      if (isLastGroup) {
        debugPrint('Es el último grupo, completando toda la operación');
        hasCompleted = true;
        timeoutTimer.cancel();
        return await completeAssignment(
            assignment.id ?? 0, endDate, endTime, context);
      }

      // Si no, enviar petición para completar sólo este grupo/trabajador
      final success = await _operationService.completeGroupOperation(
        assignment.id ?? 0,
        workerIdsToSend,
        groupId,
        endDate,
        startDate,
        startTime,
        endTime,
        context,
      );

      if (success) {
        // Actualizar en la lista local - quitar estos trabajadores o grupos
        final index = _assignments.indexWhere((a) => a.id == assignment.id);

        if (index >= 0) {
          // Obtener conjunto de IDs de los trabajadores completados

          // Si es un grupo, eliminarlo de la lista de grupos
          if (groupId != "individual" && !groupId.startsWith("worker_")) {
            // Crear una nueva lista de grupos sin el grupo completado
            final updatedGroups = _assignments[index]
                .groups
                .where((g) => g.id != groupId)
                .toList();

            // Actualizar la operación con los grupos actualizados
            _assignments[index] = Operation(
                id: assignment.id,
                area: assignment.area,
                date: assignment.date,
                time: assignment.time,
                supervisor: assignment.supervisor,
                status: assignment.status,
                endDate: assignment.endDate,
                endTime: assignment.endTime,
                zone: assignment.zone,
                motorship: assignment.motorship,
                userId: assignment.userId,
                areaId: assignment.areaId,
                clientId: assignment.clientId,
                inChagers: assignment.inChagers,
                groups: updatedGroups, // Actualizar con la lista filtrada
                id_clientProgramming: assignment.id_clientProgramming);
          } else {
            // Si no es un grupo, solo actualizar la lista de trabajadores
            _assignments[index] = Operation(
              id: assignment.id,
              area: assignment.area,
              date: assignment.date,
              time: assignment.time,
              supervisor: assignment.supervisor,
              status: assignment.status,
              endDate: assignment.endDate,
              endTime: assignment.endTime,
              zone: assignment.zone,
              motorship: assignment.motorship,
              userId: assignment.userId,
              areaId: assignment.areaId,
              clientId: assignment.clientId,
              inChagers: assignment.inChagers,
              groups: assignment.groups,
              id_clientProgramming: assignment.id_clientProgramming,
            );
          }
        }
        notifyListeners();
      }

      _isLoading = false;
      hasCompleted = true;
      timeoutTimer.cancel();
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error en completeGroupOrIndividual: $e');
      _error = 'Error: $e';
      _isLoading = false;
      hasCompleted = true;
      timeoutTimer.cancel();
      notifyListeners();
      return false;
    }
  }

  void _startRefreshTimer() {
    // debugPrint('Iniciando temporizador de refresco...');
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_lastContext != null) {
        refreshActiveAssignments(_lastContext!);
      }
    });
  }

  // Método para refrescar solo asignaciones activas
  Future<void> refreshActiveAssignments(BuildContext context) async {
    _lastContext = context;

    // debugPrint('Refrescando asignaciones activas...');

    try {
      // Refrescar solo asignaciones activas y pendientes
      final updatedAssignments = await _operationService
          .fetchOperationsByStatus(context, ['INPROGRESS', 'PENDING']);

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

  Future<bool> completeAssignment(
      int id, DateTime endDate, String endTime, BuildContext context) async {
    // debugPrint('Completando operación...');
    try {
      final success = await _operationService.completeOperation(
          id, 'COMPLETED', endDate, endTime, context);

      if (success) {
        final index = _assignments.indexWhere((a) => a.id == id);
        if (index >= 0) {
          final currentAssignment = _assignments[index];
          _assignments[index] = Operation(
            id: currentAssignment.id,
            // workers: currentAssignment.workers,
            area: currentAssignment.area,
            // task: currentAssignment.task,
            date: currentAssignment.date,
            time: currentAssignment.time,
            zone: currentAssignment.zone,
            status: 'COMPLETED',
            endDate: currentAssignment.endDate ?? endDate,
            endTime: currentAssignment.endTime ?? endTime,
            motorship: currentAssignment.motorship,
            userId: currentAssignment.userId,
            areaId: currentAssignment.areaId,
            // taskId: currentAssignment.taskId,
            clientId: currentAssignment.clientId,
            inChagers: currentAssignment.inChagers,
            groups: currentAssignment.groups,
            id_clientProgramming: currentAssignment.id_clientProgramming,
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error al completar la operación: $e');
      return false;
    }
  }

// Añadir este método al provider de asignaciones
  Future<bool> removeGroupFromAssignment(Map<String, List<int>> workersGroups,
      BuildContext context, int assigmentId) async {
    try {
      // Llamar al servicio para eliminar el grupo en el backend
      final success = await _operationService.removeGroupFromOperation(
          assigmentId, context, workersGroups);

      if (success) {
        // Si fue exitoso, actualizar la operación local
        final index = _assignments.indexWhere((a) => a.id == assigmentId);
        if (index >= 0) {
          // Crear una copia actualizada de la operación sin el grupo
          final updatedGroups = _assignments[index]
              .groups
              .where((g) => !workersGroups.containsKey(g.id))
              .toList();

          // Actualizar la operación
          _assignments[index] = Operation(
            id: _assignments[index].id,
            // workers: _assignments[index].workers,
            area: _assignments[index].area,
            // task: _assignments[index].task,
            date: _assignments[index].date,
            time: _assignments[index].time,
            zone: _assignments[index].zone,
            status: _assignments[index].status,
            endDate: _assignments[index].endDate,
            endTime: _assignments[index].endTime,
            motorship: _assignments[index].motorship,
            userId: _assignments[index].userId,
            areaId: _assignments[index].areaId,
            // taskId: _assignments[index].taskId,
            clientId: _assignments[index].clientId,
            inChagers: _assignments[index].inChagers,
            groups: updatedGroups,
            deletedWorkers: _assignments[index].deletedWorkers,
            id_clientProgramming: _assignments[index].id_clientProgramming,
          );

          notifyListeners();
        }

        return true;
      } else {
        _error = "Error al eliminar el grupo en el servidor";
        return false;
      }
    } catch (e) {
      debugPrint('Error en removeGroupFromAssignment: $e');
      _error = 'Error: $e';
      return false;
    }
  }

  Future<void> loadAssignments(BuildContext context) async {
    // debugPrint('Cargando asignaciones...');
    _isLoading = true;
    _error = null; // Resetear error previo
    notifyListeners();

    try {
      // debugPrint('Intentando cargar asignaciones desde API...');
      final operations = await _operationService.fetchOperations(context);

      // Limpiar lista existente
      _assignments.clear();

      // Añadir nuevas asignaciones
      _assignments.addAll(operations);
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
    // debugPrint('Guardando asignaciones...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = json.encode(
          _assignments.map((assignment) => assignment.toJson()).toList());
      await prefs.setString('assignments', assignmentsJson);
    } catch (e) {
      debugPrint('Error saving assignments: $e');
    }
  }

// Añadir este método al provider de asignaciones
  Future<bool> connectWorkersToAssignment(
      List<int> individualWorkerIds,
      List<Map<String, dynamic>> groupsToConnect,
      BuildContext context,
      int assignmentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Llamar al servicio para conectar los trabajadores en el backend
      final success = await _operationService.connectWorkersToOperation(
          assignmentId, individualWorkerIds, groupsToConnect, context);

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      debugPrint('Error en connectWorkersToAssignment: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

// Método actualizado para agregar operación con todos los campos
  Future<bool> addAssignment({
    required String area,
    required int areaId,
    required DateTime date,
    required String time,
    required int zoneId,
    required int userId,
    required int clientId,
    int? id_clientProgramming,
    required List<int> chargerIds,
    required List<WorkerGroup> groups,
    String? clientName,
    DateTime? endDate,
    String? endTime,
    String? motorship,
    BuildContext? context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAssignment = Operation(
        area: area,
        date: date,
        time: time,
        zone: zoneId,
        status: 'PENDING',
        endDate: endDate,
        endTime: endTime,
        motorship: motorship,
        userId: userId,
        areaId: areaId,
        clientId: clientId,
        inChagers: chargerIds,
        groups: groups,
        id_clientProgramming: id_clientProgramming,
      );

      CreateOperationDto response = CreateOperationDto(id: 0, isSuccess: false);
      if (context != null) {
        response =
            await _operationService.createOperation(newAssignment, context);
        newAssignment.id = response.id;
      }

      if (response.isSuccess) {
        // NUEVO: Refrescar la operación para obtener los IDs reales de los grupos
        if (context != null && response.id > 0) {
          await _refreshCreatedOperation(response.id, context);
        } else {
          // Si no se puede refrescar, agregar la operación con IDs temporales
          _assignments.add(newAssignment);
        }

        // NUEVO: Actualizar estado de la programación si existe
        if (id_clientProgramming != null && context != null) {
          await _updateProgrammingStatus(
              id_clientProgramming, 'ASSIGNED', context);
        }

        await _saveAssignments();
      } else {
        _error = "Error al crear la operación en el servidor";
      }

      WorkerGroupsProvider workerGroupsProvider =
          Provider.of<WorkerGroupsProvider>(context!, listen: false);
      workerGroupsProvider.groups.clear();

      _isLoading = false;
      notifyListeners();
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error al agregar operación: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

//  Refrescar una operación específica después de crearla
  Future<void> _refreshCreatedOperation(
      int operationId, BuildContext context) async {
    try {
      debugPrint('Refrescando operación creada con ID: $operationId');

      // Obtener la operación específica del backend
      final refreshedOperations = await _operationService
          .fetchOperationsByStatus(context, ['PENDING', 'INPROGRESS']);

      // Buscar la operación específica en la respuesta usando where (más seguro)
      final matchingOperations =
          refreshedOperations.where((op) => op.id == operationId).toList();

      if (matchingOperations.isNotEmpty) {
        final refreshedOperation = matchingOperations.first;

        debugPrint(
            'Operación refrescada exitosamente con ${refreshedOperation.groups.length} grupos');

        // Agregar la operación refrescada con los IDs reales
        _assignments.add(refreshedOperation);

        // Imprimir los IDs reales de los grupos para debug
        for (var group in refreshedOperation.groups) {
          debugPrint(
              'Grupo refrescado - ID real: ${group.id}, Nombre: ${group.name}');
        }
      } else {
        debugPrint(
            'No se pudo encontrar la operación $operationId en la respuesta del backend');
        debugPrint(
            'Operaciones encontradas: ${refreshedOperations.map((op) => op.id).toList()}');
      }
    } catch (e) {
      debugPrint('Error al refrescar operación creada: $e');
      // No throw error, solo log, para no afectar el flujo principal
    }
  }

// NUEVO MÉTODO: Actualizar estado de programación
  Future<void> _updateProgrammingStatus(
      int programmingId, String newStatus, BuildContext context) async {
    try {
      debugPrint(
          'Actualizando programación $programmingId a estado $newStatus');

      final programmingsProvider =
          Provider.of<ProgrammingsProvider>(context, listen: false);
      final success = await programmingsProvider.updateProgrammingStatus(
          programmingId, newStatus, context);

      if (success) {
        debugPrint(
            'Programación $programmingId actualizada exitosamente a $newStatus');
      } else {
        debugPrint('Error al actualizar programación $programmingId');
      }
    } catch (e) {
      debugPrint('Error al actualizar estado de programación: $e');
    }
  }

  Future<void> updateAssignmentStatus(
      int id, String status, BuildContext context) async {
    // debugPrint('Actualizando estado de la operación...');
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final currentAssignment = _assignments[index];
      _assignments[index] = Operation(
        id: currentAssignment.id,
        // workers: currentAssignment.workers,
        area: currentAssignment.area,
        // task: currentAssignment.task,
        date: currentAssignment.date,
        time: currentAssignment.time,
        zone: currentAssignment.zone,
        status: status,
        endDate: currentAssignment.endDate,
        endTime: currentAssignment.endTime,
        motorship: currentAssignment.motorship,
        userId: currentAssignment.userId,
        areaId: currentAssignment.areaId,
        // taskId: currentAssignment.taskId,
        clientId: currentAssignment.clientId,
        inChagers: currentAssignment.inChagers,
        groups: currentAssignment.groups,
        id_clientProgramming: currentAssignment.id_clientProgramming,
      );

      // debugPrint('Actualizando estado de la operación en el backend...');

      await _operationService.updateStatusOperation(id, status, context);

      await _saveAssignments();
      notifyListeners();
    }
  }

  Future<void> updateAssignmentEndTime(int id, String endTime) async {
    // debugPrint('Actualizando hora de finalización de la operación...');
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final currentAssignment = _assignments[index];
      _assignments[index] = Operation(
        id: currentAssignment.id,
        // workers: currentAssignment.workers,
        area: currentAssignment.area,
        // task: currentAssignment.task,
        date: currentAssignment.date,
        time: currentAssignment.time,
        zone: currentAssignment.zone,
        status: currentAssignment.status,
        endDate: currentAssignment.endDate,
        endTime: endTime,
        motorship: currentAssignment.motorship,
        userId: currentAssignment.userId,
        areaId: currentAssignment.areaId,
        // taskId: currentAssignment.taskId,
        clientId: currentAssignment.clientId,
        inChagers: currentAssignment.inChagers,
        id_clientProgramming: currentAssignment.id_clientProgramming,
        groups: currentAssignment.groups,
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

  Operation? getAssignmentById(String id) {
    // debugPrint('Obteniendo operación por ID...');
    try {
      return _assignments.firstWhere(
        (a) => a.id == id,
        orElse: () => Operation(
            // workers: [],
            area: "",
            // task: "",
            date: DateTime.now(),
            time: "",
            zone: 0,
            userId: 0,
            areaId: 0,
            // taskId: 0,
            clientId: 0,
            inChagers: [],
            id_clientProgramming: 0),
      );
    } catch (e) {
      return null;
    }
  }

  // Añadir este nuevo método al AssignmentsProvider
  Future<bool> updateAssignment(
      Operation updatedAssignment, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Actualizar en el backend
      final success = await _operationService.completeOperation(
          updatedAssignment.id ?? 0,
          updatedAssignment.status,
          updatedAssignment.endDate ?? DateTime.now(),
          updatedAssignment.endTime ?? '',
          context);

      if (success) {
        // Actualizar en la lista local
        final index =
            _assignments.indexWhere((a) => a.id == updatedAssignment.id);
        if (index >= 0) {
          _assignments[index] = updatedAssignment;
        }
      } else {
        _error = "Error al actualizar la operación en el servidor";
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
    // debugPrint('Cargando asignaciones con prioridad...');
    // No establecer isLoading = true si ya hay datos para evitar reconstrucciones innecesarias
    final hasExistingData = _assignments.isNotEmpty;

    if (!hasExistingData) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Primera fase: Cargar asignaciones activas y pendientes (alta prioridad)
      final highPriorityAssignments = await _operationService
          .fetchOperationsByStatus(context, ['INPROGRESS', 'PENDING']);

      // Actualizar primero las asignaciones de alta prioridad
      if (highPriorityAssignments.isNotEmpty) {
        // Actualizar asignaciones actuales
        _updateAssignmentsList(highPriorityAssignments);

        // Notificar cambios para actualizar la UI inmediatamente
        if (!hasExistingData) {
          _isLoading = false;
        }
        notifyListeners();
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
    // debugPrint('Cargando asignaciones completadas en segundo plano...');
    try {
      final completedAssignments = await _operationService
          .fetchOperationsByStatus(context, ['COMPLETED']);

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
  void _updateAssignmentsList(List<Operation> newAssignments) {
    for (var newAssignment in newAssignments) {
      final index = _assignments.indexWhere((a) => a.id == newAssignment.id);
      if (index >= 0) {
        // Actualizar operación existente
        _assignments[index] = newAssignment;
      } else {
        // Añadir nueva operación
        _assignments.add(newAssignment);
      }
    }
  }
}
