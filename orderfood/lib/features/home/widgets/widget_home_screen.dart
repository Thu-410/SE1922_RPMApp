import 'package:flutter/material.dart';
import 'package:orderfood/features/menu/screens/menu_screen.dart';
import 'package:orderfood/features/cart/screens/cart_screen.dart';
import 'package:orderfood/features/payment/screens/payment_screen.dart';
import 'package:orderfood/features/notification/screens/notification_screen.dart';
import 'package:orderfood/features/account/screens/account_screen.dart';

Widget buildNavBox(IconData icon, String label, BuildContext context) {
  return InkWell(
    onTap: () {
      // TODO: điều hướng tới màn hình tương ứng
      if (label == "Menu") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      } else if (label == "Order") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderScreen()),
        );
      } else if (label == "Payment") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
      } else if (label == "Notification") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      } else if (label == "Account") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountScreen()),
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.indigo),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

Widget buildBanner(String title, String subtitle) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.indigo.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fastfood, size: 50, color: Colors.indigo),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget buildFoodCard(String name, String price) {
  return Container(
    width: 120,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: const Offset(2, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.fastfood, size: 40, color: Colors.indigo),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          price,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
}
