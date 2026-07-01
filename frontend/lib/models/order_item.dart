class OrderItem {
  final int foodId;
  final String foodName;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['food_id'],
      foodName: json['food_name'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}
