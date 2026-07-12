class MonthlyRevenueModel {
  final int month;
  final int? year;
  final num revenue;
  final num totalRevenue;
  final int totalPaidInvoices;

  MonthlyRevenueModel({
    required this.month,
    this.year,
    required this.revenue,
    required this.totalRevenue,
    required this.totalPaidInvoices,
  });

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> json) {
    num toNum(dynamic value) => num.tryParse('${value ?? 0}') ?? 0;
    int toInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

    return MonthlyRevenueModel(
      month: toInt(json['month']),
      year: json['year'] == null ? null : toInt(json['year']),
      revenue: toNum(json['revenue']),
      totalRevenue: toNum(json['total_revenue']),
      totalPaidInvoices: toInt(json['total_paid_invoices']),
    );
  }
}

class DebtModel {
  final int invoiceId;
  final int month;
  final int year;
  final num totalAmount;
  final String status;
  final String? dueDate;
  final String? roomNumber;
  final String? tenantName;
  final String? tenantPhone;

  DebtModel({
    required this.invoiceId,
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.status,
    this.dueDate,
    this.roomNumber,
    this.tenantName,
    this.tenantPhone,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    num toNum(dynamic value) => num.tryParse('${value ?? 0}') ?? 0;
    int toInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

    return DebtModel(
      invoiceId: toInt(json['invoice_id']),
      month: toInt(json['month']),
      year: toInt(json['year']),
      totalAmount: toNum(json['total_amount']),
      status: json['status']?.toString() ?? '',
      dueDate: json['due_date']?.toString(),
      roomNumber: json['room_number']?.toString(),
      tenantName: json['tenant_name']?.toString(),
      tenantPhone: json['tenant_phone']?.toString(),
    );
  }
}

class OccupancyRoomModel {
  final int id;
  final String roomNumber;
  final int? floor;
  final num? area;
  final num? price;
  final String status;
  final String? tenantName;
  final String? tenantPhone;

  OccupancyRoomModel({
    required this.id,
    required this.roomNumber,
    this.floor,
    this.area,
    this.price,
    required this.status,
    this.tenantName,
    this.tenantPhone,
  });

  factory OccupancyRoomModel.fromJson(Map<String, dynamic> json) {
    num? toNum(dynamic value) => value == null ? null : num.tryParse('$value');
    int? toInt(dynamic value) => value == null ? null : int.tryParse('$value');

    return OccupancyRoomModel(
      id: int.tryParse('${json['id']}') ?? 0,
      roomNumber: json['room_number']?.toString() ?? '',
      floor: toInt(json['floor']),
      area: toNum(json['area']),
      price: toNum(json['price']),
      status: json['status']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString(),
      tenantPhone: json['tenant_phone']?.toString(),
    );
  }
}
