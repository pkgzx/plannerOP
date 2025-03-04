import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerStatusHelper {
  static String getText(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.available:
        return 'Disponible';
      case WorkerStatus.assigned:
        return 'Asignado';
      case WorkerStatus.incapacitated:
        return 'Incapacitado';
      case WorkerStatus.deactivated:
        return 'Retirado';
      default:
        return 'Estado Desconocido';
    }
  }

  static Color getColor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.available:
        return Colors.green;
      case WorkerStatus.assigned:
        return Colors.amber;
      case WorkerStatus.incapacitated:
        return Colors.purple;
      case WorkerStatus.deactivated:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  static IconData getIcon(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.available:
        return Icons.check_circle_outline;
      case WorkerStatus.assigned:
        return Icons.assignment_turned_in;
      case WorkerStatus.incapacitated:
        return Icons.medical_services_outlined;
      case WorkerStatus.deactivated:
        return Icons.exit_to_app;
      default:
        return Icons.help_outline;
    }
  }
}

// Paleta de colores para áreas específicas
final Map<String, Color> areaColors = {
  'CAFE': const Color(0xFF795548),
  'CARGA GENERAL': const Color(0xFF2196F3),
  'CARGA REFRIGERADA': const Color(0xFF00BCD4),
  'CARGA PELIGROSA': const Color(0xFFFF5722),
  'OPERADORES MC': const Color(0xFF9C27B0),
  'ADMINISTRATIVA': const Color(0xFF607D8B),
};

// Obtener color para un área específica o devolver un color predeterminado
Color getColorForArea(String area) {
  return areaColors[area.toUpperCase()] ?? const Color(0xFF4299E1);
}
