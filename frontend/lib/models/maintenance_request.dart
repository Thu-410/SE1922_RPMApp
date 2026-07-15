class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.issueType = 'other',
    this.roomNumber,
    this.tenantName,
    this.tenantPhone,
    this.imageUrl,
    this.managerNote,
    this.assignedStaffName,
    this.createdAt,
  });
  final int id;
  final String title;
  final String description;
  final String status;
  final String issueType;
  final String? roomNumber;
  final String? tenantName;
  final String? tenantPhone;
  final String? imageUrl;
  final String? managerNote;
  final String? assignedStaffName;
  final DateTime? createdAt;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      MaintenanceRequest(
        id: NumberParser.integer(json['id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        issueType: json['issue_type']?.toString() ?? 'other',
        roomNumber: json['room_number']?.toString(),
        tenantName: json['tenant_name']?.toString(),
        tenantPhone: json['tenant_phone']?.toString(),
        imageUrl: json['image_url']?.toString(),
        managerNote: json['manager_note']?.toString(),
        assignedStaffName: json['assigned_staff_name']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class NumberParser {
  static int integer(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
  static double decimal(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
