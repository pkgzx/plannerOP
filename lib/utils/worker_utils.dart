import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerUtils {
  static Color getAvatarColor(String specialization) {
    // Color basado en la especialización
    switch (specialization.toLowerCase()) {
      case 'carpintero':
        return const Color(0xFF8B4513); // Marrón oscuro
      case 'electricista':
        return const Color(0xFF4B0082); // Índigo
      case 'plomero':
        return const Color(0xFF1E90FF); // Azul dodger
      case 'albañil':
        return const Color(0xFF696969); // Gris oscuro
      case 'pintor':
        return const Color(0xFF2E8B57); // Verde mar
      default:
        return const Color(0xFF4299E1); // Azul predeterminado
    }
  }

  static List<String> getSkillsForSpecialization(String specialization) {
    // Simulamos habilidades basadas en la especialización
    switch (specialization.toLowerCase()) {
      case 'carpintero':
        return ['Carpintería fina', 'Montaje', 'Lijado', 'Barnizado', 'Corte'];
      case 'electricista':
        return [
          'Cableado',
          'Instalación',
          'Reparaciones',
          'Diagnóstico',
          'Normativa'
        ];
      case 'plomero':
        return [
          'Fontanería',
          'Soldadura',
          'Reparaciones',
          'Instalación',
          'Tuberías'
        ];
      case 'albañil':
        return ['Mampostería', 'Enlucido', 'Solado', 'Hormigón', 'Reformas'];
      default:
        return ['Experiencia general', 'Trabajo en equipo', 'Puntualidad'];
    }
  }

  // Obtener un color consistente para cada trabajador basado en su ID
  static Color getColorForWorker(Worker worker) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    final int index = worker.id % colors.length;
    return colors[index];
  }
}
