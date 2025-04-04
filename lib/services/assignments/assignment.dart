import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
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
      for (WorkerGroup group in assignment.groups) {
        debugPrint("Grupo: ${group.name}");
      }
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
        "groups": assignment.groups.map((group) {
          return {
            "dateStart": group.startDate,
            "dateEnd": group.endDate,
            "timeStart": group.startTime,
            "timeEnd": group.endTime,
            "workerIds":
                group.workers.map((workerId) => {"id": workerId}).toList()
          };
        }).toList(),
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

// Modificación de fetchAssignmentsByStatus para evitar duplicados de trabajadores
  Future<List<Assignment>> fetchAssignmentsByStatus(
      BuildContext context, List<String> statusList) async {
    try {
      // Verificaciones iniciales (sin cambios)
      if (!context.mounted) {
        debugPrint(
            'Context no está montado, abortando fetchAssignmentsByStatus');
        return [];
      }

      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;
      var url = Uri.parse(
          '$API_URL/operation/by-status?status=${statusList.join(",")}');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      debugPrint('Response: ${response.body}');

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
          // Usar un mapa para evitar duplicados basados en el ID
          Map<int, Worker> workersMap = {};

          // Lista para grupos de trabajadores
          List<WorkerGroup> assignmentGroups = [];

          // PASO 1: Primero procesar trabajadores individuales si existen
          if (assignment['workers'] != null && assignment['workers'] is List) {
            var individualWorkers = assignment['workers'] as List;

            for (var worker in individualWorkers) {
              final workerId = worker['id_worker'] ?? 0;

              if (workerId == 0) continue;

              try {
                if (workers.isEmpty) continue;

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

                // Solo añadir si es un trabajador válido (id no es 0)
                if (workerObj.id != 0) {
                  workersMap[workerObj.id] = workerObj;
                }
              } catch (e) {
                debugPrint(
                    'Error al procesar trabajador individual ID $workerId: $e');
              }
            }
          }

          // PASO 2: Ahora procesar los grupos de trabajadores
          if (assignment['workerGroups'] != null &&
              assignment['workerGroups'] is List) {
            var workerGroups = assignment['workerGroups'] as List;

            // Conjunto para rastrear IDs de trabajadores ya procesados
            Set<int> processedWorkerIds = {};

            for (var group in workerGroups) {
              // Extraer información del schedule
              var schedule = group['schedule'] ?? {};
              final dateStart = schedule['dateStart'];
              final dateEnd = schedule['dateEnd'];
              final timeStart = schedule['timeStart'];
              final timeEnd = schedule['timeEnd'];

              // Verificar si este grupo tiene un horario definido
              final hasSchedule = (dateStart != null && dateStart != "") ||
                  (dateEnd != null && dateEnd != "") ||
                  (timeStart != null && timeStart != "") ||
                  (timeEnd != null && timeEnd != "");

              // Procesar los trabajadores de este grupo
              List<int> groupWorkerIds = [];

              if (group['workers'] != null && group['workers'] is List) {
                for (var workerData in group['workers']) {
                  final workerId = workerData['id'] ?? 0;

                  // Saltar si ya procesamos este trabajador o ID inválido
                  if (workerId == 0 || processedWorkerIds.contains(workerId))
                    continue;

                  processedWorkerIds.add(workerId);

                  try {
                    if (workers.isEmpty) continue;

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

                    // Si no es el trabajador orElse y ID válido
                    if (workerObj.id != 0) {
                      // Añadir al mapa SOLO si no existe ya
                      if (!workersMap.containsKey(workerObj.id)) {
                        workersMap[workerObj.id] = workerObj;
                      }

                      // Si tiene horario, añadirlo al grupo
                      if (hasSchedule) {
                        groupWorkerIds.add(workerObj.id);
                      }
                    }
                  } catch (e) {
                    debugPrint('Error al procesar trabajador ID $workerId: $e');
                  }
                }
              }

              // Crear un WorkerGroup solo si tiene horario definido y trabajadores
              if (hasSchedule && groupWorkerIds.isNotEmpty) {
                // Crear nombre descriptivo
                String groupName;
                if (timeStart != null &&
                    timeStart.isNotEmpty &&
                    timeEnd != null &&
                    timeEnd.isNotEmpty) {
                  groupName = 'Grupo $timeStart - $timeEnd';
                } else if (timeStart != null && timeStart.isNotEmpty) {
                  groupName = 'Grupo $timeStart';
                } else if (timeEnd != null && timeEnd.isNotEmpty) {
                  groupName = 'Grupo $timeEnd';
                } else if (dateStart != null &&
                    dateStart.isNotEmpty &&
                    dateEnd != null &&
                    dateEnd.isNotEmpty) {
                  try {
                    final startFormatted =
                        DateTime.parse(dateStart).toString().substring(0, 10);
                    final endFormatted =
                        DateTime.parse(dateEnd).toString().substring(0, 10);
                    groupName = 'Grupo $startFormatted - $endFormatted';
                  } catch (e) {
                    groupName =
                        'Grupo ${DateTime.now().millisecondsSinceEpoch}';
                  }
                } else {
                  groupName = 'Grupo ${DateTime.now().millisecondsSinceEpoch}';
                }

                // Añadir el grupo a la lista de grupos
                assignmentGroups.add(WorkerGroup(
                  startTime: timeStart,
                  endTime: timeEnd,
                  workers: groupWorkerIds,
                  name: groupName,
                  id: 'group_${DateTime.now().millisecondsSinceEpoch}_${groupWorkerIds.length}',
                ));
              }
            }
          }

          // DIAGNÓSTICO: Mostrar información sobre los trabajadores procesados
          debugPrint(
              'Asignación ${assignment['id']}: Trabajadores únicos: ${workersMap.length}');
          debugPrint(
              'Asignación ${assignment['id']}: Grupos: ${assignmentGroups.length}');

          // Procesar encargados
          List<int> inChargers = [];
          var inChargeData =
              assignment['inChargeOperation'] ?? assignment['inCharge'] ?? [];

          if (inChargeData is List && inChargeData.isNotEmpty) {
            inChargers = List<int>.from(inChargeData.map((item) {
              return item is Map ? (item['id_user'] ?? item['id'] ?? 0) : 0;
            })).where((id) => id != 0).toList();
          }

          var assignmentObj = Assignment(
            id: assignment['id'],
            workers: workersMap.values.toList(),
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
            inChagers: inChargers,
            groups: assignmentGroups,
          );

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
        debugPrint("Response200: ${response.body}");
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
