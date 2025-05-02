import 'package:intl/intl.dart';

String getGroupName(DateTime? startDate, DateTime? endDate, String? startTime,
    String? endTime) {
  // Reemplazar la generación del nombre de grupo
  String groupName = 'Grupo';

  // Determinar si las fechas son diferentes
  bool hasDifferentDates = startDate != null &&
      endDate != null &&
      DateFormat('yyyy-MM-dd').format(startDate!) !=
          DateFormat('yyyy-MM-dd').format(endDate!);

  // Caso 1: Tiene todos los campos de horario (fecha y hora de inicio y fin)
  if (startDate != null &&
      endDate != null &&
      startTime != null &&
      endTime != null) {
    if (hasDifferentDates) {
      // Fechas diferentes: mostrar ambas fechas completas con horas
      groupName =
          'Grupo ${DateFormat('dd/MM').format(startDate!)} $startTime - ${DateFormat('dd/MM').format(endDate!)} $endTime';
    } else {
      // Misma fecha: mostrar fecha una vez con ambas horas
      groupName =
          'Grupo ${DateFormat('dd/MM').format(startDate!)} $startTime-$endTime';
    }
  }
  // Caso 2: Solo tiene fechas (sin horas)
  else if (startDate != null && endDate != null) {
    if (hasDifferentDates) {
      groupName =
          'Grupo ${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}';
    } else {
      groupName = 'Grupo ${DateFormat('dd/MM').format(startDate!)}';
    }
  }
  // Caso 3: Solo tiene horas (sin fechas)
  else if (startTime != null && endTime != null) {
    groupName = 'Grupo $startTime-$endTime';
  }
  // Caso 4: Combinaciones parciales
  else if (startDate != null && startTime != null) {
    groupName = 'Grupo ${DateFormat('dd/MM').format(startDate!)} $startTime';
  } else if (endDate != null && endTime != null) {
    groupName = 'Grupo fin ${DateFormat('dd/MM').format(endDate!)} $endTime';
  }
  // Caso 5: Solo una fecha o hora
  else if (startDate != null) {
    groupName = 'Grupo inicio ${DateFormat('dd/MM').format(startDate!)}';
  } else if (endDate != null) {
    groupName = 'Grupo fin ${DateFormat('dd/MM').format(endDate!)}';
  } else if (startTime != null) {
    groupName = 'Grupo inicio $startTime';
  } else if (endTime != null) {
    groupName = 'Grupo fin $endTime';
  }

  return groupName;
}
