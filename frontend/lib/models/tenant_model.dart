class Tenant {
  final int id;
  final int? userId;
  final int? roomId;
  final String fullName;
  final String phone;
  final String? email;
  final String? citizenId;
  final String? dateOfBirth;
  final String? hometown;
  final String? address;
  final String? citizenFrontImageUrl;
  final String? citizenBackImageUrl;
  final bool isRepresentative;
  final String status;
  final String? roomNumber;

  Tenant({
    required this.id,
    this.userId,
    this.roomId,
    required this.fullName,
    required this.phone,
    this.email,
    this.citizenId,
    this.dateOfBirth,
    this.hometown,
    this.address,
    this.citizenFrontImageUrl,
    this.citizenBackImageUrl,
    this.isRepresentative = false,
    this.status = 'active',
    this.roomNumber,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      userId: json['user_id'],
      roomId: json['room_id'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      citizenId: json['citizen_id'],
      dateOfBirth: json['date_of_birth'],
      hometown: json['hometown'],
      address: json['address'],
      citizenFrontImageUrl: json['citizen_front_image_url'],
      citizenBackImageUrl: json['citizen_back_image_url'],
      isRepresentative: json['is_representative'] == 1 || json['is_representative'] == true,
      status: json['status'] ?? 'active',
      roomNumber: json['room_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'citizen_id': citizenId,
      'date_of_birth': dateOfBirth,
      'hometown': hometown,
      'address': address,
      'citizen_front_image_url': citizenFrontImageUrl,
      'citizen_back_image_url': citizenBackImageUrl,
      'is_representative': isRepresentative,
      'status': status,
    };
  }
}