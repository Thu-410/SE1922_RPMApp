import 'maintenance_request.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.unpaidInvoices,
    required this.overdueInvoices,
    required this.currentMonthRevenue,
    required this.totalDebtAmount,
    required this.pendingRequests,
  });
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int unpaidInvoices;
  final int overdueInvoices;
  final double currentMonthRevenue;
  final double totalDebtAmount;
  final int pendingRequests;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalRooms: NumberParser.integer(json['total_rooms']),
        occupiedRooms: NumberParser.integer(json['occupied_rooms']),
        availableRooms: NumberParser.integer(json['available_rooms']),
        unpaidInvoices: NumberParser.integer(json['unpaid_invoices']),
        overdueInvoices: NumberParser.integer(json['overdue_invoices']),
        currentMonthRevenue: NumberParser.decimal(
          json['current_month_revenue'],
        ),
        totalDebtAmount: NumberParser.decimal(json['total_debt_amount']),
        pendingRequests: NumberParser.integer(json['pending_requests']),
      );
}

class MonthlyRevenue {
  const MonthlyRevenue({
    required this.month,
    required this.year,
    required this.totalRevenue,
    required this.paidInvoices,
  });
  final int month;
  final int year;
  final double totalRevenue;
  final int paidInvoices;
  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) => MonthlyRevenue(
    month: NumberParser.integer(json['month']),
    year: NumberParser.integer(json['year']),
    totalRevenue: NumberParser.decimal(
      json['total_revenue'] ?? json['revenue'],
    ),
    paidInvoices: NumberParser.integer(json['total_paid_invoices']),
  );
}

class DebtItem {
  const DebtItem({
    required this.invoiceId,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    this.roomNumber,
    this.tenantName,
    this.dueDate,
  });
  final int invoiceId;
  final int month;
  final int year;
  final double amount;
  final String status;
  final String? roomNumber;
  final String? tenantName;
  final DateTime? dueDate;
  factory DebtItem.fromJson(Map<String, dynamic> json) => DebtItem(
    invoiceId: NumberParser.integer(json['invoice_id']),
    month: NumberParser.integer(json['month']),
    year: NumberParser.integer(json['year']),
    amount: NumberParser.decimal(json['total_amount']),
    status: json['status']?.toString() ?? '',
    roomNumber: json['room_number']?.toString(),
    tenantName: json['tenant_name']?.toString(),
    dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
  );
}

class OccupancyRoom {
  const OccupancyRoom({
    required this.id,
    required this.roomNumber,
    required this.status,
    required this.price,
    this.floor,
    this.tenantName,
  });
  final int id;
  final String roomNumber;
  final String status;
  final double price;
  final int? floor;
  final String? tenantName;
  factory OccupancyRoom.fromJson(Map<String, dynamic> json) => OccupancyRoom(
    id: NumberParser.integer(json['id']),
    roomNumber: json['room_number']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    price: NumberParser.decimal(json['price']),
    floor: json['floor'] == null ? null : NumberParser.integer(json['floor']),
    tenantName: json['tenant_name']?.toString(),
  );
}
