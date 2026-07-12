class DashboardSummaryModel {
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int maintenanceRooms;
  final int inactiveRooms;
  final int unpaidInvoices;
  final int overdueInvoices;
  final int paidInvoices;
  final num totalPaidInvoiceAmount;
  final num totalDebtAmount;
  final num currentMonthRevenue;
  final int totalMaintenanceRequests;
  final int pendingRequests;
  final int processingRequests;
  final int completedRequests;
  final int cancelledRequests;

  DashboardSummaryModel({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.maintenanceRooms,
    required this.inactiveRooms,
    required this.unpaidInvoices,
    required this.overdueInvoices,
    required this.paidInvoices,
    required this.totalPaidInvoiceAmount,
    required this.totalDebtAmount,
    required this.currentMonthRevenue,
    required this.totalMaintenanceRequests,
    required this.pendingRequests,
    required this.processingRequests,
    required this.completedRequests,
    required this.cancelledRequests,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
    num toNum(dynamic value) => num.tryParse('${value ?? 0}') ?? 0;

    return DashboardSummaryModel(
      totalRooms: toInt(json['total_rooms']),
      occupiedRooms: toInt(json['occupied_rooms']),
      availableRooms: toInt(json['available_rooms']),
      maintenanceRooms: toInt(json['maintenance_rooms']),
      inactiveRooms: toInt(json['inactive_rooms']),
      unpaidInvoices: toInt(json['unpaid_invoices']),
      overdueInvoices: toInt(json['overdue_invoices']),
      paidInvoices: toInt(json['paid_invoices']),
      totalPaidInvoiceAmount: toNum(json['total_paid_invoice_amount']),
      totalDebtAmount: toNum(json['total_debt_amount']),
      currentMonthRevenue: toNum(json['current_month_revenue']),
      totalMaintenanceRequests: toInt(json['total_maintenance_requests']),
      pendingRequests: toInt(json['pending_requests']),
      processingRequests: toInt(json['processing_requests']),
      completedRequests: toInt(json['completed_requests']),
      cancelledRequests: toInt(json['cancelled_requests']),
    );
  }
}
