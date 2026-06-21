import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu"), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildMenuItem("Phở Bò", "50.000đ"),
            _buildMenuItem("Bún Chả", "45.000đ"),
            _buildMenuItem("Pizza", "99.000đ"),
            _buildMenuItem("Trà Sữa", "35.000đ"),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String name, String price) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.fastfood, color: Colors.indigo),
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(price, style: const TextStyle(color: Colors.black54)),
        trailing: ElevatedButton(
          onPressed: () {
            // TODO: thêm vào giỏ hàng
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text("Thêm"),
        ),
      ),
    );
  }
}
