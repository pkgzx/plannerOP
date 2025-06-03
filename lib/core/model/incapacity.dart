class Incapacity {
  final String? id;
  final IncapacityType type;
  final IncapacityCause cause;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final int workerId;

  Incapacity({
    this.id,
    required this.type,
    required this.cause,
    this.startDate,
    this.endDate,
    this.createdAt,
    required this.workerId,
  });

  @override
  String toString() {
    return 'Incapacity{id: $id, type: $type, cause: $cause, startDate: $startDate, endDate: $endDate, createdAt: $createdAt, workerId: $workerId}';
  }

  // Método corregido para el formato que espera la API
  Map<String, dynamic> toJson() {
    return {
      'dateDisableStart': startDate != null ? _formatDate(startDate!) : null,
      'dateDisableEnd': endDate != null ? _formatDate(endDate!) : null,
      'type': _mapTypeToApi(type),
      'cause': _mapCauseToApi(cause),
      'id_worker': workerId,
    };
  }

  // Formatear fecha en formato YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Mapear tipo a los valores que espera la API
  String _mapTypeToApi(IncapacityType type) {
    switch (type) {
      case IncapacityType.INITIAL:
        return 'INITIAL';
      case IncapacityType.EXTENSION:
        return 'EXTENSION';
    }
  }

  // Mapear causa a los valores que espera la API
  String _mapCauseToApi(IncapacityCause cause) {
    switch (cause) {
      case IncapacityCause.LABOR:
        return 'LABOR';
      case IncapacityCause.TRANSIT:
        return 'TRANSIT';
      case IncapacityCause.DISEASE:
        return 'DISEASE';
    }
  }

  // Método original para otros usos internos de la app
  Map<String, dynamic> toInternalJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'cause': cause.toString().split('.').last,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'workerId': workerId,
    };
  }
}

enum IncapacityType { INITIAL, EXTENSION }

enum IncapacityCause { LABOR, TRANSIT, DISEASE }
