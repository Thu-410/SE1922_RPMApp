import 'order_item.dart';

class Order {
  final int id;

  final double totalAmount;

  final String orderStatus;
  final String paymentStatus;

  final List<OrderItem> items;

  Order({
    required this.id,
    required this.totalAmount,
    required this.orderStatus,
    required this.paymentStatus,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      orderStatus: json['order_status'],
      paymentStatus: json['payment_status'],
      items: [],
    );
  }
}
