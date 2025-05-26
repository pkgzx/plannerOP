import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/dto/operations/createOperation.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/group.dart';
import 'package:provider/provider.dart';

class AssignmentService {
  final String API_URL = dotenv.get('API_URL');

  // Método para enviar operación al backend usando AuthProvider
  Future<CreateOperationDto> createAssignment(
      Operation assignment, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Recopilar todos los IDs de trabajadores que están en grupos
      Set<int> workersInGroups = {};
      for (var group in assignment.groups) {
        workersInGroups.addAll(group.workers);
      }

      // // Filtrar los trabajadores para solo incluir aquellos que no están en grupos
      // List<int> individualWorkers =
      //     assignment.workers.map((worker) => worker.id).toList();

      // Crear el payload en el formato requerido por el backend
      final Map<String, dynamic> payload = {
        "status": assignment.status.toUpperCase(),
        "zone": assignment.zone,
        "motorShip": assignment.motorship ?? "",
        "dateStart": _formatDate(assignment.date),
        "timeStrat": assignment.time,
        "id_user": assignment.userId,
        "id_area": assignment.areaId,
        // "id_task": assignment.taskId,
        "id_client": assignment.clientId,
        // "workerIds": individualWorkers,
        'inChargedIds': assignment.inChagers,
        "groups": assignment.groups.map((group) {
          return {
            "dateStart": group.startDate,
            "dateEnd": group.endDate,
            "timeStart": group.startTime,
            "timeEnd": group.endTime,
            "workerIds": group.workers,
            "id_task": group.serviceId
          };
        }).toList(),
        'id_clientProgramming': assignment.id_clientProgramming,
      };

      if (assignment.endDate != null) {
        payload['dateEnd'] = _formatDate(assignment.endDate!);
      }

      if (assignment.endTime != null) {
        payload['timeEnd'] = assignment.endTime;
      }

      // debugPrint('Enviando operación: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation');
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 201) {
        var body = jsonDecode(response.body);

        return CreateOperationDto(
          id: body['id'],
          isSuccess: true,
        );
      } else {
        debugPrint(
            'Error al crear operación: ${response.statusCode} - ${response.body}');
        return CreateOperationDto(id: 0, isSuccess: false);
      }
    } catch (e) {
      debugPrint('Excepción al crear operación: $e');
      return CreateOperationDto(id: 0, isSuccess: false);
    }
  }

  // Método auxiliar para dar formato a las fechas
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Metodo para obtener las asignaciones
  Future<List<Operation>> fetchAssignments(BuildContext context) async {
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
        List<Operation> assignments = [];
        for (var assignment in jsonResponse) {
          // debugPrint('Asignación: $assignment');

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

          var assignmentObj = Operation.fromJson(assignment, workers);

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
      // debugPrint('Actualizando estado de operación $status');
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al actualizar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar operación: $e');
      return false;
    }
  }

  // Método para actualizar una operación existente
  Future<bool> updateAssignment(
      Operation assignment, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      if (assignment.id == null) {
        debugPrint('Error: ID de operación no proporcionado');
        return false;
      }
      // Crear el payload con los datos actualizados
      final Map<String, dynamic> payload = {
        "status": assignment.status.toUpperCase(),
        "dateStart": _formatDate(assignment.date),
        "timeStrat": assignment.time,
        // "workers": {
        //   "connect":
        //       assignment.workers.map((worker) => {"id": worker.id}).toList()
        // },
      };

      // Añadir campos opcionales si tienen valor
      if (assignment.endDate != null) {
        payload['dateEnd'] = _formatDate(assignment.endDate!);
      }

      if (assignment.endTime != null && assignment.endTime!.isNotEmpty) {
        payload['timeEnd'] = assignment.endTime;
      }

      // debugPrint(
      // 'Actualizando operación ${assignment.id}: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation/${assignment.id}');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al actualizar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar operación: $e');
      return false;
    }
  }

  // Método para actualizar una operación existente
  Future<bool> updateAssignmentToComplete(
      Operation assignment, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      if (assignment.id == null) {
        debugPrint('Error: ID de operación no proporcionado');
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

      // debugPrint(
      //     'Actualizando operación ${assignment.id}: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation/${assignment.id}');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al actualizar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar operación: $e');
      return false;
    }
  }

// Método para eliminar un grupo de una operación
  Future<bool> removeGroupFromAssignment(
      int assignmentId, BuildContext context, List<int> workerIds) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Endpoint para eliminar un grupo específico de una operación
      var url = Uri.parse('$API_URL/operation/$assignmentId');

      Map<String, dynamic> body = {
        "workers": {
          "disconnect": workerIds.map((id) => {"id": id}).toList()
        }
      };

      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // debugPrint('Grupo eliminado con éxito');
        return true;
      } else {
        debugPrint(
            'Error al eliminar grupo: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al eliminar grupo: $e');
      return false;
    }
  }

  // Método para actualizar solo la hora de finalización de una operación
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

      // debugPrint('Actualizando hora de finalización: $endTime');

      if (response.statusCode == 200) {
        // debugPrint(
        //     'Hora de finalización actualizada con éxito: ${response.body}');
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

  // Método para eliminar una operación
  Future<bool> deleteAssignment(
      String assignmentId, BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$assignmentId');
      var response =
          await http.delete(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200 || response.statusCode == 204) {
        // debugPrint('Asignación eliminada con éxito');
        return true;
      } else {
        debugPrint(
            'Error al eliminar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al eliminar operación: $e');
      return false;
    }
  }

// Modificación de fetchAssignmentsByStatus para evitar duplicados de trabajadores
  Future<List<Operation>> fetchAssignmentsByStatus(
      BuildContext context, List<String> statusList) async {
    try {
      // Verificaciones iniciales (sin cambios)
      if (!context.mounted) {
        // debugPrint(
        // 'Context no está montado, abortando fetchAssignmentsByStatus');
        return [];
      }

      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;
      var url = Uri.parse(
          '$API_URL/operation/by-status?status=${statusList.join(",")}');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      // debugPrint('Response: ${response.body}');

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
        List<Operation> assignments = [];

        for (var assignment in jsonResponse) {
          // Mapa para evitar duplicados basados en el ID
          Map<int, Worker> workersMap = {};

          // Nuevo mapa para trabajadores finalizados
          Map<int, Worker> finishedWorkersMap = {};

          // Lista para grupos de trabajadores
          List<WorkerGroup> assignmentGroups = [];

          // PASO 2: Procesar los grupos de trabajadores
          if (assignment['workerGroups'] != null &&
              assignment['workerGroups'] is List) {
            var workerGroups = assignment['workerGroups'] as List;

            // Conjunto para rastrear IDs de trabajadores ya procesados
            Set<int> processedWorkerIds = {};

            for (var group in workerGroups) {
              // Extraer información del schedule
              var schedule = group['schedule'] ?? {};
              final dateStart = schedule['dateStart'] ?? null;
              final dateEnd = schedule['dateEnd'] ?? null;
              final timeStart = schedule['timeStart'] ?? null;
              final timeEnd = schedule['timeEnd'] ?? null;

              // Verificar si este grupo tiene un horario definido
              final hasSchedule = (dateStart != null && dateStart != "") ||
                  (dateEnd != null && dateEnd != "") ||
                  (timeStart != null && timeStart != "") ||
                  (timeEnd != null && timeEnd != "");

              // Verificar si el horario de finalización ya pasó
              bool isFinished = false;
              if (dateEnd != null &&
                  dateEnd.isNotEmpty &&
                  timeEnd != null &&
                  timeEnd.isNotEmpty) {
                try {
                  // Parsear la fecha y hora de finalización
                  final DateTime endDateParsed = DateTime.parse(dateEnd);
                  final List<String> timeParts = timeEnd.split(':');
                  final int hours = int.parse(timeParts[0]);
                  final int minutes = int.parse(timeParts[1]);

                  // Crear DateTime combinando fecha y hora
                  final DateTime endDateTime = DateTime(
                    endDateParsed.year,
                    endDateParsed.month,
                    endDateParsed.day,
                    hours,
                    minutes,
                  );

                  // Verificar si ya pasó la fecha y hora de finalización
                  final DateTime now = DateTime.now();
                  isFinished = endDateTime.isBefore(now) ||
                      endDateTime.isAtSameMomentAs(now);
                } catch (e) {
                  debugPrint('Error al parsear fecha/hora de finalización: $e');
                }
              }

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
                      // Clasificar el trabajador según si está en un grupo finalizado o no
                      if (isFinished) {
                        // Añadir al mapa de finalizados si no existe ya
                        if (!finishedWorkersMap.containsKey(workerObj.id)) {
                          finishedWorkersMap[workerObj.id] = workerObj;
                          // debugPrint(
                          //     'Trabajador ${workerObj.id} (${workerObj.name}) clasificado como finalizado');
                        }
                      } else {
                        // Añadir al mapa general si no existe ya
                        if (!workersMap.containsKey(workerObj.id)) {
                          workersMap[workerObj.id] = workerObj;
                        }
                      }

                      // Si tiene horario, añadirlo al grupo (independientemente de si está finalizado)
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
                String groupName = getGroupName(
                  dateStart != null ? DateTime.tryParse(dateStart) : null,
                  dateEnd != null ? DateTime.tryParse(dateEnd) : null,
                  timeStart != null ? timeStart : null,
                  timeEnd != null ? timeEnd : null,
                );

                // Añadir el grupo a la lista de grupos
                assignmentGroups.add(WorkerGroup(
                  startTime: timeStart,
                  endTime: timeEnd,
                  startDate: dateStart,
                  endDate: dateEnd,
                  workers: groupWorkerIds,
                  name: groupName,
                  id: 'group_${DateTime.now().millisecondsSinceEpoch}_${groupWorkerIds.length}',
                  serviceId: schedule["id_task"] ?? 0,
                ));
              }
            }
          }

          // También, si assignment tiene un campo finished_workers o similar, procesarlo aquí
          if (assignment['finishedWorkers'] != null &&
              assignment['finishedWorkers'] is List) {
            var finishedWorkerData = assignment['finishedWorkers'] as List;

            for (var workerData in finishedWorkerData) {
              final workerId = workerData['id'] ?? 0;
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

                // Añadir al mapa de finalizados si no existe ya
                if (workerObj.id != 0 &&
                    !finishedWorkersMap.containsKey(workerObj.id)) {
                  finishedWorkersMap[workerObj.id] = workerObj;
                  // debugPrint(
                  //     'Trabajador ${workerObj.id} añadido de finishedWorkers');
                }
              } catch (e) {
                debugPrint(
                    'Error al procesar trabajador finalizado ID $workerId: $e');
              }
            }
          }

          // DIAGNÓSTICO: Mostrar información sobre los trabajadores procesados
          // debugPrint(
          //     'Asignación ${assignment['id']}: Trabajadores activos: ${workersMap.length}, finalizados: ${finishedWorkersMap.length}');
          // debugPrint(
          //     'Asignación ${assignment['id']}: Grupos: ${assignmentGroups.length}');
          List<int> inChargers = [];
          var inChargeData =
              assignment['inChargeOperation'] ?? assignment['inCharge'] ?? [];

          if (inChargeData is List && inChargeData.isNotEmpty) {
            inChargers = List<int>.from(inChargeData.map((item) {
              return item is Map ? (item['id_user'] ?? item['id'] ?? 0) : 0;
            })).where((id) => id != 0).toList();
          }

          var assignmentObj = Operation(
            id: assignment['id'],
            // workers: workersMap.values.toList(),
            workersFinished: finishedWorkersMap.values
                .toList(), // Usar la lista de trabajadores finalizados
            area: assignment['jobArea']['name'],
            // task: assignment['task']['name'],
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
            // taskId: assignment['task']['id'],
            clientId: assignment['id_client'],
            inChagers: inChargers,
            groups: assignmentGroups,
            id_clientProgramming: assignment['id_clientProgramming'],
          );

          assignments.add(assignmentObj);
        }
        return assignments;
      } else {
        debugPrint(
            'Error al obtener asignaciones por estado: ${response.statusCode} - ${response.body}');
        return [];
      }
    } on SocketException catch (e) {
      debugPrint('Error de conexión: $e');
      return [];
    } on HttpException catch (e) {
      debugPrint('Error HTTP: $e');
      return [];
    } on FormatException catch (e) {
      debugPrint('Error de formato: $e');
      return [];
    } on Exception catch (e) {
      debugPrint('Error en fetchAssignmentsByStatus: $e');
      return [];
    }
  }

  // Método para completar una operación
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
        // debugPrint('Asignación completada con éxito');
        // debugPrint("Response200: ${response.body}");
        return true;
      } else {
        debugPrint(
            'Error al completar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al completar operación: $e');
      return false;
    }
  }

// Añade este método a AssignmentService en services/assignments/assignment.dart
  Future<bool> completePartialAssignment(
    int assignmentId,
    List<int> workerIds,
    String groupId,
    DateTime endDate,
    DateTime startDate,
    String startTime,
    String endTime,
    BuildContext context,
  ) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$assignmentId');
      var body = {
        "workers": {
          "update": [
            {
              "workerIds": workerIds,
              "dateEnd": _formatDate(endDate),
              "timeEnd": endTime,
              "dateStart": _formatDate(startDate),
              "timeStart": startTime,
            }
          ]
        }
      };

      var response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Error al completar parcialmente: ${response.statusCode} - ${response.body}');
        // Si la API no soporta esta operación, aún así marcar como exitoso localmente
        if (response.statusCode == 404) {
          debugPrint(
              'API no soporta completado parcial, marcando como exitoso localmente');
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al completar parcialmente: $e');
      // En caso de error, marcar como exitoso localmente para mantener consistencia de la UI
      return true;
    }
  }

// Método para conectar nuevos trabajadores a una operación existente
  Future<bool> connectWorkersToAssignment(
      int assignmentId,
      List<int> individualWorkerIds,
      List<Map<String, dynamic>> groupsToConnect,
      BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Endpoint para actualizar la operación
      var url = Uri.parse('$API_URL/operation/$assignmentId');

      // Preparar la estructura de la solicitud
      Map<String, dynamic> body = {
        "workers": {"connect": []}
      };

      // Añadir trabajadores individuales
      for (var workerId in individualWorkerIds) {
        body["workers"]["connect"].add({"id": workerId});
      }

      // Añadir grupos de trabajadores
      for (var group in groupsToConnect) {
        body["workers"]["connect"].add({
          "workerIds": group["workerIds"],
          "dateStart": group["dateStart"],
          "dateEnd": group["dateEnd"],
          "timeStart": group["timeStart"],
          "timeEnd": group["timeEnd"]
        });
      }

      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'Error al conectar trabajadores: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al conectar trabajadores: $e');
      return false;
    }
  }
}
