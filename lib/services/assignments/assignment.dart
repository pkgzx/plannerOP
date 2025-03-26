import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/dto/assignment/createAssigment.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class AssignmentService {
  final String API_URL = dotenv.get('API_URL');

  // Método para enviar asignación al backend usando AuthProvider
  Future<CreateassigmentDto> createAssignment(
      Assignment assignment, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Crear el payload en el formato requerido por el backend
      final Map<String, dynamic> payload = {
        "status": assignment.status.toUpperCase(),
        "zone": assignment.zone,
        "motorShip": assignment.motorship ?? "",
        "dateStart": _formatDate(assignment.date),
        "timeStrat": assignment.time,
        "id_user": assignment.userId,
        "id_area": assignment.areaId,
        "id_task": assignment.taskId,
        "id_client": assignment.clientId,
        "workerIds": assignment.workers.map((worker) => worker.id).toList(),
        'inChargedIds': assignment.inChagers,
      };

      if (assignment.endDate != null) {
        payload['dateEnd'] = _formatDate(assignment.endDate!);
      }

      if (assignment.endTime != null) {
        payload['timeEnd'] = assignment.endTime;
      }

      debugPrint('Enviando asignación: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation');
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 201) {
        var body = jsonDecode(response.body);

        return CreateassigmentDto(
          id: body['id'],
          isSuccess: true,
        );
      } else {
        debugPrint(
            'Error al crear asignación: ${response.statusCode} - ${response.body}');
        return CreateassigmentDto(id: 0, isSuccess: false);
      }
    } catch (e) {
      debugPrint('Excepción al crear asignación: $e');
      return CreateassigmentDto(id: 0, isSuccess: false);
    }
  }

  // Método auxiliar para dar formato a las fechas
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Metodo para obtener las asignaciones
  Future<List<Assignment>> fetchAssignments(BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      var workers_provider =
          Provider.of<WorkersProvider>(context, listen: false);
      var workers = workers_provider.workers;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Assignment> assignments = [];
        for (var assignment in jsonResponse) {
          debugPrint('Asignación: $assignment');

          var mapWorkers = assignment['workers'];
          List<Worker> workersAssignment = [];

          for (var worker in mapWorkers) {
            var workerId = worker['id_worker'];
            var workerObj = workers.firstWhere((w) => w.id == workerId,
                orElse: () => Worker(
                    name: "",
                    area: "",
                    phone: "",
                    document: "",
                    status: WorkerStatus.available,
                    startDate: DateTime.now(),
                    code: "",
                    id: 0));
            workersAssignment.add(workerObj);
          }

          var assignmentObj = Assignment(
              id: assignment['id'],
              workers: workersAssignment,
              area: assignment['jobArea']['name'],
              task: assignment['task']['name'],
              date: DateTime.parse(assignment['dateStart']),
              time: assignment['timeStrat'],
              status: assignment['status'],
              endTime: assignment['timeEnd'],
              endDate: assignment['dateEnd'] != null
                  ? DateTime.parse(assignment['dateEnd'])
                  : null,
              zone: assignment['zone'],
              motorship: assignment['motorShip'],
              userId: assignment['id_user'],
              areaId: assignment['jobArea']['id'],
              taskId: assignment['task']['id'],
              clientId: assignment['id_client'],
              inChagers: assignment['inChargedIds'] ?? []);

          debugPrint('Asignación creada: $assignmentObj');

          assignments.add(assignmentObj);
        }
        return assignments;
      } else {
        debugPrint(
            'Error al obtener asignaciones: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en fetchAssignments: $e');
      return [];
    }
  }

  Future<bool> updateStatusAssignment(
      int assignmentId, String status, BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$assignmentId');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(
              {"status": status == 'IN_PROGRESS' ? 'INPROGRESS' : status}));
      debugPrint('Actualizando estado de asignación $status');
      if (response.statusCode == 200) {
        debugPrint('Asignación actualizada con éxito: ${response.body}');
        return true;
      } else {
        debugPrint(
            'Error al actualizar asignación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar asignación: $e');
      return false;
    }
  }

  // Método para actualizar una asignación existente
  Future<bool> updateAssignment(
      Assignment assignment, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      if (assignment.id == null) {
        debugPrint('Error: ID de asignación no proporcionado');
        return false;
      }
      // Crear el payload con los datos actualizados
      final Map<String, dynamic> payload = {
        "status": assignment.status.toUpperCase(),
        "dateStart": _formatDate(assignment.date),
        "timeStrat": assignment.time,
        "workers": {
          "connect":
              assignment.workers.map((worker) => {"id": worker.id}).toList()
        },
      };

      debugPrint('Asignación actualizada: ${jsonEncode(payload)}');

      // Añadir campos opcionales si tienen valor
      if (assignment.endDate != null) {
        payload['dateEnd'] = _formatDate(assignment.endDate!);
      }

      if (assignment.endTime != null && assignment.endTime!.isNotEmpty) {
        payload['timeEnd'] = assignment.endTime;
      }

      debugPrint(
          'Actualizando asignación ${assignment.id}: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation/${assignment.id}');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        debugPrint('Asignación actualizada con éxito: ${response.body}');
        return true;
      } else {
        debugPrint(
            'Error al actualizar asignación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar asignación: $e');
      return false;
    }
  }

  // Método para actualizar una asignación existente
  Future<bool> updateAssignmentToComplete(
      Assignment assignment, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      if (assignment.id == null) {
        debugPrint('Error: ID de asignación no proporcionado');
        return false;
      }
      // Crear el payload con los datos actualizados
      final Map<String, dynamic> payload = {
        "status": assignment.status.toUpperCase(),
      };

      // Añadir campos opcionales si tienen valor
      if (assignment.endDate != null) {
        payload['dateEnd'] = _formatDate(assignment.endDate!);
      }

      if (assignment.endTime != null && assignment.endTime!.isNotEmpty) {
        payload['timeEnd'] = assignment.endTime;
      }

      debugPrint(
          'Actualizando asignación ${assignment.id}: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation/${assignment.id}');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        debugPrint('Asignación actualizada con éxito: ${response.body}');
        return true;
      } else {
        debugPrint(
            'Error al actualizar asignación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar asignación: $e');
      return false;
    }
  }

  // Método para actualizar solo la hora de finalización de una asignación
  Future<bool> updateAssignmentEndTime(
      String assignmentId, String endTime, BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$assignmentId/end-time');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({"timeEnd": endTime}));

      debugPrint('Actualizando hora de finalización: $endTime');

      if (response.statusCode == 200) {
        debugPrint(
            'Hora de finalización actualizada con éxito: ${response.body}');
        return true;
      } else {
        debugPrint(
            'Error al actualizar hora de finalización: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar hora de finalización: $e');
      return false;
    }
  }

  // Método para eliminar una asignación
  Future<bool> deleteAssignment(
      String assignmentId, BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$assignmentId');
      var response =
          await http.delete(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Asignación eliminada con éxito');
        return true;
      } else {
        debugPrint(
            'Error al eliminar asignación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al eliminar asignación: $e');
      return false;
    }
  }

// Modifica el método fetchAssignmentsByStatus para manejar el contexto de forma segura
  Future<List<Assignment>> fetchAssignmentsByStatus(
      BuildContext context, List<String> statusList) async {
    try {
      // Verificar si el contexto sigue montado antes de usarlo
      if (!context.mounted) {
        debugPrint(
            'Context no está montado, abortando fetchAssignmentsByStatus');
        return [];
      }

      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Construir parámetros de consulta para filtrar por estado
      final queryParams =
          statusList.map((status) => 'status=$status').join('&');
      var url = Uri.parse('$API_URL/operation?$queryParams');

      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      // Verificar nuevamente si el contexto sigue montado después de la operación asíncrona
      if (!context.mounted) {
        debugPrint(
            'Context ya no está montado después de la llamada HTTP, abortando');
        return [];
      }

      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);
      final workers = workersProvider.workers;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Assignment> assignments = [];

        for (var assignment in jsonResponse) {
          var mapWorkers = assignment['workers'];
          List<Worker> workersAssignment = [];

          for (var worker in mapWorkers) {
            try {
              var workerId = worker['id_worker'];
              if (workers.length == 0) {
                return [];
              }

              var workerObj = workers.firstWhere((w) => w.id == workerId,
                  orElse: () => Worker(
                      name: "",
                      area: "",
                      phone: "",
                      document: "",
                      status: WorkerStatus.available,
                      startDate: DateTime.now(),
                      code: "",
                      id: 0));

              workersAssignment.add(workerObj);
            } catch (e) {
              debugPrint('Trabajador no encontrado: ${worker['id_worker']}');
              // Continuar con el siguiente trabajador
            }
          }

          List<int> inChargers = [];

          if (assignment['inChargeOperation'].length == 0) {
            inChargers = [];
          } else {
            inChargers = List<int>.from(assignment['inChargeOperation'].map(
                (item) =>
                    item is int ? item : int.tryParse(item.toString()) ?? 0));
          }

          var assignmentObj = Assignment(
              id: assignment['id'],
              workers: workersAssignment,
              area: assignment['jobArea']['name'],
              task: assignment['task']['name'],
              date: DateTime.parse(assignment['dateStart']),
              time: assignment['timeStrat'],
              status: assignment['status'],
              endTime: assignment['timeEnd'],
              endDate: assignment['dateEnd'] != null
                  ? DateTime.parse(assignment['dateEnd'])
                  : null,
              zone: assignment['zone'],
              motorship: assignment['motorShip'],
              userId: assignment['id_user'],
              areaId: assignment['jobArea']['id'],
              taskId: assignment['task']['id'],
              clientId: assignment['id_client'],
              inChagers: inChargers);

          assignments.add(assignmentObj);
        }
        return assignments;
      } else {
        debugPrint(
            'Error al obtener asignaciones por estado: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en fetchAssignmentsByStatus: $e');
      return [];
    }
  }

  // Método para completar una asignación
  Future<bool> completeAssigment(
    int assignmentId,
    String status,
    DateTime endDate,
    String endTime,
    BuildContext context,
  ) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$assignmentId');
      var body = {
        'status': status,
        'dateEnd': _formatDate(endDate),
        'timeEnd': endTime,
      };

      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        debugPrint('Asignación completada con éxito');
        return true;
      } else {
        debugPrint(
            'Error al completar asignación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al completar asignación: $e');
      return false;
    }
  }
}
