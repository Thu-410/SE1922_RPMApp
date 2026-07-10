class SessionUser {
  const SessionUser({required this.id, required this.fullName, required this.role});
  final int id;
  final String fullName;
  final String role;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        id: json['id'] as int,
        fullName: json['full_name'].toString(),
        role: json['role'].toString(),
      );
}
