class User {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;

  User({required this.id, required this.fullName, this.phone, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
    );
  }
}
