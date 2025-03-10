import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class AssignmentService {
  final String API_URL = dotenv.get('API_URL');

  // Método para enviar asignación al backend usando AuthProvider
  Future<bool> createAssignment(
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
        "dateEnd":
            assignment.endDate != null ? _formatDate(assignment.endDate!) : "",
        "timeEnd": assignment.endTime ?? "",
        "id_user": assignment.userId,
        "id_area": assignment.areaId,
        "id_task": assignment.taskId,
        "id_client": assignment.clientId,
        "workerIds": assignment.workers.map((worker) => worker.id).toList(),
      };

      debugPrint('Enviando asignación: ${jsonEncode(payload)}');

      var url = Uri.parse('$API_URL/operation');
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Asignación creada con éxito: ${response.body}');
        return true;
      } else {
        debugPrint(
            'Error al crear asignación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al crear asignación: $e');
      return false;
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
            var workerObj = workers.firstWhere((w) => w.id == workerId);
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
          );

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
          body: jsonEncode({"status": status}));

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
}
