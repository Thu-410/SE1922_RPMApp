import 'cart_item.dart';

class Cart {
  final List<CartItem> items;

  Cart({required this.items});

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
