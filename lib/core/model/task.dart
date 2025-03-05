class Task {
  final String name;
  final int id;

  Task({
    required this.name,
    required this.id,
  });

  @override
  String toString() => name;

  // Factory constructor para crear desde JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
