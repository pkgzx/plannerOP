import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:http/http.dart' as http;

class AssignmentService {
  final String API_URL = dotenv.get('API_URL');

  // Método para cargar asignacion
  Future<bool> addAssignment(Assignment assignment, String token) async {
    try {
      var url = Uri.parse('$API_URL/operation');
      var response = await http.post(url,
          headers: {'Authorization': 'Bearer $token'},
          body: {'status': 'PENDING', 'zone': assignment.zone});

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
