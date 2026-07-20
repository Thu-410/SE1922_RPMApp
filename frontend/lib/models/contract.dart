class RentalContract {
  const RentalContract({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.monthlyPrice,
    required this.depositAmount,
    required this.status,
    this.note,
    this.terminatedAt,
    this.roomNumber,
    this.tenantName,
    this.tenantPhone,
  });
  final int id, roomId, tenantId;
  final String startDate, endDate, status;
  final double monthlyPrice, depositAmount;
  final String? note, terminatedAt, roomNumber, tenantName, tenantPhone;
  factory RentalContract.fromJson(Map<String, dynamic> json) => RentalContract(
    id: int.tryParse('${json['id']}') ?? 0,
    roomId: int.tryParse('${json['room_id']}') ?? 0,
    tenantId: int.tryParse('${json['tenant_id']}') ?? 0,
    startDate: json['start_date']?.toString() ?? '',
    endDate: json['end_date']?.toString() ?? '',
    monthlyPrice: double.tryParse('${json['monthly_price']}') ?? 0,
    depositAmount: double.tryParse('${json['deposit_amount']}') ?? 0,
    status: json['status']?.toString() ?? 'pending',
    note: json['note']?.toString(),
    terminatedAt: json['terminated_at']?.toString(),
    roomNumber: json['room_number']?.toString(),
    tenantName: json['tenant_name']?.toString(),
    tenantPhone: json['tenant_phone']?.toString(),
  );
}

String contractStatusLabel(String value) => switch (value) {
  'pending' => 'Chờ hiệu lực',
  'active' => 'Đang hoạt động',
  'expired' => 'Hết hạn',
  'terminated' => 'Đã kết thúc',
  _ => value,
};
