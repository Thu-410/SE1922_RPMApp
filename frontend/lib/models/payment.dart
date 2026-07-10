class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.roomNumber,
    required this.tenantName,
    required this.amount,
    required this.method,
    required this.paymentDate,
  });

  final int id;
  final int invoiceId;
  final String roomNumber;
  final String tenantName;
  final double amount;
  final String method;
  final DateTime paymentDate;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as int,
        invoiceId: json['invoice_id'] as int,
        roomNumber: json['room_number']?.toString() ?? '',
        tenantName: json['tenant_name']?.toString() ?? '',
        amount: (json['amount'] as num).toDouble(),
        method: json['payment_method'].toString(),
        paymentDate: DateTime.parse(json['payment_date'].toString()),
      );
}
