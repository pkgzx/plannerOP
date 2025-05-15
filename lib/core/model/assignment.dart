import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';

class Assignment {
  int? id;
  final List<Worker> workers;
  List<Worker> workersFinished = [];
  final List<int> inChagers;
  final String area;
  final String task;
  final DateTime date;
  final String time;
  final User? supervisor;
  final String? endTime;
  final String status; // 'PENDING', 'INPROGRESS', 'COMPLETED', 'CANCELED'
  final DateTime? endDate;
  final int zone;
  final String? motorship;
  final int userId;
  final int areaId;
  final int taskId;
  final int clientId;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Worker> deletedWorkers = [];
  List<WorkerGroup> groups = [];

  set endTime(String? endTime) {
    this.endTime = endTime;
  }

  set endDate(DateTime? endDate) {
    this.endDate = endDate;
  }

  Assignment({
    this.id,
    required this.workers,
    required this.inChagers,
    required this.area,
    required this.task,
    required this.date,
    required this.time,
    this.endTime,
    required this.zone,
    this.status = 'PENDING',
    this.endDate,
    this.motorship,
    this.supervisor,
    this.deletedWorkers = const [],
    required this.userId,
    required this.areaId,
    required this.taskId,
    required this.clientId,
    this.createdAt,
    this.updatedAt,
    this.groups = const [],
    this.workersFinished = const [],
    // required this.groups,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workers': workers.map((worker) => worker.id).toList(),
      'area': area,
      'task': task,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'endTime': endTime,
      'endDate': endDate?.toIso8601String(),
      'zone': zone,
      'motorship': motorship,
      'userId': userId,
      'areaId': areaId,
      'taskId': taskId,
      'clientId': clientId,
      'inChargedIds': inChagers,
    };
  }

  static Assignment fromJson(
      Map<String, dynamic> json, List<Worker> workers, User supervisor) {
    return Assignment(
      id: json['id'],
      workers: json['workers'], // ! NOT WORKING
      area: json['jobArea']['name'],
      task: json['task']['name'],
      date: DateTime.parse(json['dateStart']),
      time: json['timeStrat'],
      status: json['status'],
      endTime: json['timeEnd'],
      endDate: json['dateEnd'] != null ? DateTime.parse(json['dateEnd']) : null,
      zone: json['zone'],
      motorship: json['motorship'],
      userId: json['id_user'],
      areaId: json['jobArea']['id'],
      taskId: json['task']['id'],
      clientId: json['id_client'],
      inChagers: json['chagers'], // ! NOT WORKING
      createdAt: DateTime.parse(json['createAt']),
      updatedAt: DateTime.parse(json['updateAt']),
    );
  }
}
