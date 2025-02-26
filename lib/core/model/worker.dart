class Worker {
  final String name;
  final String position;
  final String zone;
  final String schedule;
  final String task;
  final DateTime startDate;
  final DateTime? endDate;

  Worker({
    required this.name,
    required this.position,
    required this.zone,
    required this.schedule,
    required this.task,
    required this.startDate,
    this.endDate,
  });
}
