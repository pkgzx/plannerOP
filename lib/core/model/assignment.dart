class Assignment {
  final String id;
  final List<Map<String, dynamic>> workers;
  final String area;
  final String task;
  final DateTime date;
  final String time;
  String endTime;
  String status; // 'pending', 'in_progress', 'completed'
  DateTime? completedDate;

  Assignment({
    required this.id,
    required this.workers,
    required this.area,
    required this.task,
    required this.date,
    required this.time,
    required this.endTime,
    this.status = 'pending',
    this.completedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workers': workers,
      'area': area,
      'task': task,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'endTime': endTime,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      workers: List<Map<String, dynamic>>.from(json['workers']),
      area: json['area'],
      task: json['task'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      status: json['status'],
      endTime: json['endTime'],
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
    );
  }
}
