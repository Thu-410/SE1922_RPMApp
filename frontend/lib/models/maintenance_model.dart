class MaintenanceRequestModel {
  final int id;
  final int? roomId;
  final int? tenantId;
  final String title;
  final String description;
  final String? imageUrl;
  final String status;
  final String? managerNote;
  final String? createdAt;
  final String? updatedAt;
  final String? roomNumber;
  final String? tenantName;
  final String? tenantPhone;
  final String? tenantEmail;

  MaintenanceRequestModel({
    required this.id,
    this.roomId,
    this.tenantId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    this.managerNote,
    this.createdAt,
    this.updatedAt,
    this.roomNumber,
    this.tenantName,
    this.tenantPhone,
    this.tenantEmail,
  });

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: int.tryParse('${json['id']}') ?? 0,
      roomId: json['room_id'] == null ? null : int.tryParse('${json['room_id']}'),
      tenantId: json['tenant_id'] == null ? null : int.tryParse('${json['tenant_id']}'),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      managerNote: json['manager_note']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      roomNumber: json['room_number']?.toString(),
      tenantName: json['tenant_name']?.toString(),
      tenantPhone: json['tenant_phone']?.toString(),
      tenantEmail: json['tenant_email']?.toString(),
    );
  }
}
