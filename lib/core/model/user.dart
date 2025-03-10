class User {
  int id;
  String name;
  String dni;
  String phone;

  User({
    required this.id,
    required this.name,
    required this.dni,
    required this.phone,
  });

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      dni: json['dni'],
      phone: json['phone'],
    );
  }
}
