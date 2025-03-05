import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/dto/taks/fetchTask.dart';
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';

class TaskService {
  final String API_URL = dotenv.get('API_URL');

  // Método para obtener tareas con token directo
  Future<FetchTasksDto> fetchTasksWithToken(String token) async {
    try {
      var url = Uri.parse('$API_URL/task');
      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final List<Task> tasks = [];
        for (var t in jsonResponse) {
          try {
            tasks.add(Task.fromJson(t));
          } catch (e) {
            debugPrint('Error procesando tarea: $e');
          }
        }

        return FetchTasksDto(
          tasks: tasks,
          isSuccess: true,
        );
      } else {
        debugPrint('Error en API: ${response.statusCode} - ${response.body}');
        return FetchTasksDto(
          tasks: [],
          isSuccess: false,
          errorMessage: 'Error al obtener tareas: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error en fetchTasks: $e');
      return FetchTasksDto(
        tasks: [],
        isSuccess: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  // Método que utiliza el contexto para obtener el token
  Future<FetchTasksDto> fetchTasks(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return FetchTasksDto(
          tasks: [],
          isSuccess: false,
          errorMessage: 'No hay token disponible',
        );
      }

      return await fetchTasksWithToken(token);
    } catch (e) {
      debugPrint('Error en contexto de fetchTasks: $e');
      return FetchTasksDto(
        tasks: [],
        isSuccess: false,
        errorMessage: 'Error: $e',
      );
    }
  }
}
