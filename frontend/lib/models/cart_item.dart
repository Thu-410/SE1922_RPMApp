import 'food.dart';

class CartItem {
  final Food food;
  int quantity;

  CartItem({required this.food, required this.quantity});

  double get subtotal {
    return food.price * quantity;
  }
}
