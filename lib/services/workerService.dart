import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerService {
  static List<Worker> getDummyActiveAssignments() {
    return [];
  }

  static List<Worker> getDummyPendingAssignments() {
    return [];
  }

  static Color getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3182CE), // Azul
      const Color(0xFF38A169), // Verde
      const Color(0xFFDD6B20), // Naranja
      const Color(0xFF805AD5), // Morado
      const Color(0xFFE53E3E), // Rojo
      const Color(0xFF2B6CB0), // Azul oscuro
    ];

    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}
