import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerService {
  static List<Worker> getDummyActiveAssignments() {
    return [
      Worker(
        area: 'CARGA GENERAL',
        document: '12345678',
        endDate: DateTime.now().add(const Duration(days: 7)),
        name: 'Carlos Rodríguez',
        phone: '555-1234',
        startDate: DateTime.now(),
        status: WorkerStatus.assigned,
      ),
      Worker(
        area: 'CARGA REFRIGERADA',
        document: '87654321',
        endDate: DateTime.now().add(const Duration(days: 5)),
        name: 'Miguel Sánchez',
        phone: '555-5678',
        startDate: DateTime.now(),
        status: WorkerStatus.assigned,
      ),
      Worker(
        area: 'CARGA GENERAL',
        document: '13579246',
        endDate: DateTime.now().add(const Duration(days: 3)),
        name: 'Javier López',
        phone: '555-9012',
        startDate: DateTime.now(),
        status: WorkerStatus.assigned,
      ),
    ];
  }

  static List<Worker> getDummyPendingAssignments() {
    return [
      Worker(
          area: 'CARGA GENERAL',
          document: '24681357',
          name: 'Ricardo Martínez',
          phone: '555-3456',
          startDate: DateTime.now(),
          status: WorkerStatus.available),
      Worker(
          area: 'CARGA REFRIGERADA',
          document: '98765432',
          name: 'Fernando Torres',
          phone: '555-7890',
          startDate: DateTime.now(),
          status: WorkerStatus.available),
      Worker(
          area: 'CARGA GENERAL',
          document: '65432198',
          name: 'Alejandro García',
          phone: '555-2345',
          startDate: DateTime.now(),
          status: WorkerStatus.available),
    ];
  }

  static List<Worker> getDummyHistoryAssignments() {
    return [
      Worker(
        area: 'CARGA GENERAL',
        document: '12345678',
        endDate: DateTime.now().subtract(const Duration(days: 7)),
        name: 'Carlos Rodríguez',
        phone: '555-1234',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        status: WorkerStatus.deactivated,
      ),
      Worker(
        area: 'CARGA REFRIGERADA',
        document: '87654321',
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        name: 'Miguel Sánchez',
        phone: '555-5678',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        status: WorkerStatus.deactivated,
      ),
      Worker(
        area: 'CARGA GENERAL',
        document: '13579246',
        endDate: DateTime.now().subtract(const Duration(days: 3)),
        name: 'Javier López',
        phone: '555-9012',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        status: WorkerStatus.deactivated,
      ),
    ];
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
