class Contract {
  final int id;
  final int roomId;
  final int tenantId;
  final String startDate;
  final String endDate;
  final double monthlyPrice;
  final double depositAmount;
  final String status;
  final String? note;
  final String? terminatedAt;
  final String? roomNumber;
  final String? tenantName;
  final String? tenantPhone;

  Contract({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.monthlyPrice,
    this.depositAmount = 0,
    this.status = 'active',
    this.note,
    this.terminatedAt,
    this.roomNumber,
    this.tenantName,
    this.tenantPhone,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'],
      roomId: json['room_id'],
      tenantId: json['tenant_id'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      monthlyPrice: double.tryParse(json['monthly_price'].toString()) ?? 0,
      depositAmount: double.tryParse(json['deposit_amount'].toString()) ?? 0,
      status: json['status'] ?? 'pending',
      note: json['note'],
      terminatedAt: json['terminated_at'],
      roomNumber: json['room_number'],
      tenantName: json['tenant_name'],
      tenantPhone: json['tenant_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'tenant_id': tenantId,
      'start_date': startDate,
      'end_date': endDate,
      'monthly_price': monthlyPrice,
      'deposit_amount': depositAmount,
      'note': note,
    };
  }
}