import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

class FeedingService {
  final String API_URL = dotenv.get('API_URL');

  // Método para marcar alimentación entregada
  Future<bool> markFeeding({
    required int workerId,
    required int operationId,
    required String type, // "BREAKFAST", "LUNCH", "DINNER", "SNACK"
    required BuildContext context,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }
      // Obtener la fecha y hora actual formateada
      String currentDateTime = DateTime.now()
          .toIso8601String()
          .substring(0, 16)
          .replaceAll('T', ' ');

      final response = await http.post(
        Uri.parse('$API_URL/feeding'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_worker': workerId,
          'id_operation': operationId,
          'dateFeeding': currentDateTime,
          'type': type,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        showErrorToast(
            context, 'Error al registrar alimentación: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      showErrorToast(context, 'Error de conexión: $e');
      return false;
    }
  }

  Future<List<dynamic>> getFeedingsForOperation(
      int operationId, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return [];
      }

      final response = await http.get(
        Uri.parse('$API_URL/feeding/operation/$operationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> feedingData = jsonDecode(response.body);
        return feedingData;
      } else {
        debugPrint('Error al obtener alimentaciones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de conexión al obtener alimentaciones: $e');
      return [];
    }
  }
}
