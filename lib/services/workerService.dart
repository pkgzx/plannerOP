import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerService {
  static List<Worker> getDummyActiveAssignments() {
    return [
      Worker(
        name: "Carlos Méndez",
        position: "Técnico de Mantenimiento",
        zone: "Zona Norte",
        schedule: "8:00 - 17:00",
        task: "Mantenimiento preventivo",
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Worker(
        name: "Ana Gutiérrez",
        position: "Supervisora de Calidad",
        zone: "Zona Centro",
        schedule: "7:00 - 16:00",
        task: "Inspección de equipos",
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 2)),
      ),
      Worker(
        name: "Roberto Sánchez",
        position: "Técnico Eléctrico",
        zone: "Zona Sur",
        schedule: "9:00 - 18:00",
        task: "Reparación de instalación",
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 10)),
      ),
    ];
  }

  static List<Worker> getDummyPendingAssignments() {
    return [
      Worker(
        name: "Laura Torres",
        position: "Ingeniera Industrial",
        zone: "Zona Este",
        schedule: "8:00 - 17:00",
        task: "Optimización de procesos",
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 9)),
      ),
      Worker(
        name: "Miguel Díaz",
        position: "Técnico de Sistemas",
        zone: "Zona Oeste",
        schedule: "9:00 - 18:00",
        task: "Configuración de servidores",
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 8)),
      ),
    ];
  }

  static List<Worker> getDummyHistoryAssignments() {
    return [
      Worker(
        name: "Sofía Vega",
        position: "Analista de Calidad",
        zone: "Zona Norte",
        schedule: "8:00 - 17:00",
        task: "Auditoría de procesos",
        startDate: DateTime.now().subtract(const Duration(days: 20)),
        endDate: DateTime.now().subtract(const Duration(days: 13)),
      ),
      Worker(
        name: "Juan Morales",
        position: "Técnico de Seguridad",
        zone: "Zona Centro",
        schedule: "7:00 - 16:00",
        task: "Revisión de protocolos",
        startDate: DateTime.now().subtract(const Duration(days: 25)),
        endDate: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Worker(
        name: "Patricia Herrera",
        position: "Ingeniera de Sistemas",
        zone: "Zona Sur",
        schedule: "9:00 - 18:00",
        task: "Implementación de red",
        startDate: DateTime.now().subtract(const Duration(days: 40)),
        endDate: DateTime.now().subtract(const Duration(days: 33)),
      ),
      Worker(
        name: "Alejandro Ríos",
        position: "Técnico de Mantenimiento",
        zone: "Zona Este",
        schedule: "8:00 - 17:00",
        task: "Mantenimiento correctivo",
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().subtract(const Duration(days: 53)),
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
