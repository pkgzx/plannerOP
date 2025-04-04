import 'package:plannerop/core/model/worker.dart';

class WorkerGroup {
  final String? startTime;
  final String? endTime;
  final String? startDate;
  final String? endDate;
  final List<int> workers;
  final String name;
  final String id;

  WorkerGroup({
    this.startTime,
    this.endTime,
    this.startDate,
    this.endDate,
    required this.workers,
    required this.name,
    required this.id,
  });
}
