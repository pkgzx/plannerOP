class Worker {
  final String name;
  final String area;
  final String phone;
  final String document;
  final DateTime startDate;
  final DateTime? endDate;
  final WorkerStatus status;
  final String code;

  Worker({
    required this.name,
    required this.area,
    required this.phone,
    required this.document,
    required this.status,
    required this.startDate,
    required this.code,
    this.endDate,
  });
}

enum WorkerStatus {
  available,
  assigned,
  unavailable,
  deactivated,
  incapacitated,
}
