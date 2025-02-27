class Worker {
  final String name;
  final String area;
  final String phone;
  final String document;
  final DateTime startDate;
  final DateTime? endDate;
  final WorkerStatus status;

  Worker({
    required this.name,
    required this.area,
    required this.phone,
    required this.document,
    required this.status,
    required this.startDate,
    this.endDate,
  });
}

enum WorkerStatus {
  available,
  assigned,
  unavailable,
  deactivated,
}
