import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/incapacity.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/utils/constants.dart';
import 'package:provider/provider.dart';

class IncapacityService {
  final String API_URL = dotenv.get('API_URL');
  Future<bool> registerIncapacity(
      Incapacity incapacity, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      var url = Uri.parse('$API_URL/inability');
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(incapacity.toJson()),
      );

      debugPrint(
          'Incapacity API Response: ${response.statusCode} - ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error en registerIncapacity: $e');
      return false;
    }
  }

  Future<List<Incapacity>> getIncapacitiesByWorker(
      int workerId, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return [];
      }

      var url = Uri.parse('$API_URL/inability/worker/$workerId');
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((json) => _incapacityFromJson(json)).toList();
      } else {
        debugPrint('Error al obtener incapacidades: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en getIncapacitiesByWorker: $e');
      return [];
    }
  }

  //  método para buscar incapacidades con filtros
  Future<List<Incapacity>> searchIncapacities({
    int? workerId,
    DateTime? dateDisableStart,
    DateTime? dateDisableEnd,
    List<String>? types,
    List<String>? causes,
    required BuildContext context,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return [];
      }

      // Construir la URL con parámetros de consulta
      String baseUrl = '$API_URL/inability/search/filters';
      List<String> queryParams = [];

      if (workerId != null) {
        queryParams.add('id_worker=$workerId');
      }

      if (dateDisableStart != null) {
        queryParams.add('dateDisableStart=${_formatDate(dateDisableStart)}');
      }

      if (dateDisableEnd != null) {
        queryParams.add('dateDisableEnd=${_formatDate(dateDisableEnd)}');
      }

      if (types != null && types.isNotEmpty) {
        queryParams
            .add('type=${types.join('%2C%20')}'); // URL encoding para comas
      }

      if (causes != null && causes.isNotEmpty) {
        queryParams
            .add('cause=${causes.join('%2C%20')}'); // URL encoding para comas
      }

      String url = baseUrl;
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
          'Search Incapacities API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((json) => _incapacityFromJson(json)).toList();
      } else {
        debugPrint('Error al buscar incapacidades: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en searchIncapacities: $e');
      return [];
    }
  }

  // Método auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ...existing code...

  Incapacity _incapacityFromJson(Map<String, dynamic> json) {
    return Incapacity(
      id: json['id']?.toString() ?? "",
      workerId: json['id_worker'] ?? 0,
      type: _mapApiToType(json['type']),
      cause: _mapApiToCause(json['cause']),
      startDate: DateTime.parse(json['dateDisableStart']),
      endDate: DateTime.parse(json['dateDisableEnd']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  IncapacityType _mapApiToType(String apiType) {
    switch (apiType) {
      case 'INITIAL':
        return IncapacityType.INITIAL;
      case 'EXTENSION':
        return IncapacityType.EXTENSION;
      default:
        return IncapacityType.INITIAL;
    }
  }

  IncapacityCause _mapApiToCause(String apiCause) {
    switch (apiCause) {
      case 'LABOR':
        return IncapacityCause.LABOR;
      case 'TRANSIT':
        return IncapacityCause.TRANSIT;
      case 'DISEASE':
        return IncapacityCause.DISEASE;
      default:
        return IncapacityCause.DISEASE;
    }
  }
}
