import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/dto/workers/fetchWorkers.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:provider/provider.dart';

class WorkerService {
  final String API_URL = dotenv.get('API_URL');

  // Versión que acepta un token directamente, sin depender del contexto
  Future<FetchWorkersDto> fetchWorkersWithToken(String token) async {
    try {
      var url = Uri.parse('$API_URL/worker');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final List<Worker> workers = [];
        for (var w in jsonResponse) {
          try {
            // Convertir fechas de string a DateTime si es necesario
            DateTime? startDate;
            DateTime? endDate;

            if (w['createdAt'] != null) {
              startDate = DateTime.tryParse(w['createdAt'].toString());
            }

            if (w['updatedAt'] != null) {
              endDate = DateTime.tryParse(w['updatedAt'].toString());
            }

            // Determinar el estado correcto
            WorkerStatus status = WorkerStatus.available;
            if (w['status'] == 'assigned') {
              status = WorkerStatus.assigned;
            }

            workers.add(Worker(
              document: w['dni'],
              name: w['name'],
              phone: w['phone'],
              status: status,
              area: '${w['jobArea']['name']}',
              code: '${w['code']}',
              startDate: startDate ?? DateTime.now(),
              endDate: endDate ?? DateTime.now(),
            ));
          } catch (e) {
            debugPrint('Error procesando trabajador: $e');
          }
        }

        return FetchWorkersDto(workers: workers, isSuccess: true);
      } else {
        debugPrint('Error en API: ${response.statusCode} - ${response.body}');
        return FetchWorkersDto(workers: [], isSuccess: false);
      }
    } catch (e) {
      debugPrint('Error en fetchWorkers: $e');
      return FetchWorkersDto(workers: [], isSuccess: false);
    }
  }

  // Mantener la función original que usa contexto para retrocompatibilidad
  Future<FetchWorkersDto> fetchWorkers(BuildContext context) async {
    try {
      // Obtiene el token de acceso del provider de autenticación
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return FetchWorkersDto(workers: [], isSuccess: false);
      }

      return await fetchWorkersWithToken(token);
    } catch (e) {
      debugPrint('Error en contexto de fetchWorkers: $e');
      return FetchWorkersDto(workers: [], isSuccess: false);
    }
  }

  Future<void> registerWorker(Worker worker, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User user = userProvider.user;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return;
      }

      var url = Uri.parse('$API_URL/worker');
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'name': worker.name,
            'dni': worker.document,
            'phone': worker.phone,
            'id_area': 1, // TODO: Cambiar por el ID real
            'status': 'AVALIABLE',
            'id_user': user.id,
            'code': worker.code,
          }));

      debugPrint('Lo que envio: ${response.request}');

      if (response.statusCode == 201) {
        debugPrint('Trabajador registrado correctamente');
      } else {
        debugPrint('Error en API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en registerWorker: $e');
    }
  }
}
