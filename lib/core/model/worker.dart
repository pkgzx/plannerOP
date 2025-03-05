class Worker {
  final int id;
  final String name;
  final String area;
  final String phone;
  final String document;
  final DateTime startDate;
  final DateTime? endDate;
  DateTime? incapacityStartDate;
  DateTime? incapacityEndDate;
  DateTime? deactivationDate;
  int idArea;
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
    this.incapacityStartDate,
    this.incapacityEndDate,
    this.deactivationDate,
    this.idArea = 0,
    required this.id,
  });

  void setIncapacityDates(DateTime startDate, DateTime endDate) {
    incapacityStartDate = startDate;
    incapacityEndDate = endDate;
  }

  void setDeactivationDate(DateTime date) {
    deactivationDate = date;
  }
}

enum WorkerStatus {
  available,
  assigned,
  unavailable,
  deactivated,
  incapacitated,
}
