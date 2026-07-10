class InvoiceDetail {
  const InvoiceDetail({required this.name, required this.amount});
  final String name;
  final double amount;

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) => InvoiceDetail(
        name: json['item_name'].toString(),
        amount: (json['amount'] as num).toDouble(),
      );
}

class Invoice {
  const Invoice({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.tenantName,
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.status,
    required this.dueDate,
    required this.serviceFee,
    required this.parkingFee,
    required this.internetFee,
    required this.otherFee,
    required this.discount,
    this.note,
    this.details = const [],
  });

  final int id;
  final int roomId;
  final String roomNumber;
  final String tenantName;
  final int month;
  final int year;
  final double totalAmount;
  final String status;
  final DateTime dueDate;
  final double serviceFee;
  final double parkingFee;
  final double internetFee;
  final double otherFee;
  final double discount;
  final String? note;
  final List<InvoiceDetail> details;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as int,
        roomId: json['room_id'] as int,
        roomNumber: json['room_number']?.toString() ?? 'Phòng ${json['room_id']}',
        tenantName: json['tenant_name']?.toString() ?? '',
        month: json['month'] as int,
        year: json['year'] as int,
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: json['status'].toString(),
        dueDate: DateTime.parse(json['due_date'].toString()),
        serviceFee: (json['service_fee'] as num).toDouble(),
        parkingFee: (json['parking_fee'] as num).toDouble(),
        internetFee: (json['internet_fee'] as num).toDouble(),
        otherFee: (json['other_fee'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        note: json['note']?.toString(),
        details: (json['details'] as List<dynamic>? ?? [])
            .map((item) => InvoiceDetail.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
