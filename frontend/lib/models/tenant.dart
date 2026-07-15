class Tenant {
  const Tenant({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    this.userId,
    this.roomId,
    this.email,
    this.citizenId,
    this.dateOfBirth,
    this.hometown,
    this.address,
    this.isRepresentative = false,
    this.roomNumber,
    this.activeContractCount = 0,
  });
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
  final bool isRepresentative;
  final String status;
  final String? roomNumber;
  final int activeContractCount;
  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: int.tryParse('${json['id']}') ?? 0,
    userId: int.tryParse('${json['user_id']}'),
    roomId: int.tryParse('${json['room_id']}'),
    fullName: json['full_name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString(),
    citizenId: json['citizen_id']?.toString(),
    dateOfBirth: json['date_of_birth']?.toString(),
    hometown: json['hometown']?.toString(),
    address: json['address']?.toString(),
    isRepresentative:
        json['is_representative'] == true || json['is_representative'] == 1,
    status: json['status']?.toString() ?? 'active',
    roomNumber: json['room_number']?.toString(),
    activeContractCount: int.tryParse('${json['active_contract_count']}') ?? 0,
  );
}
