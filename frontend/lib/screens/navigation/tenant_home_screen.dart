import 'package:flutter/material.dart';
import '../maintenance/create_maintenance_request_screen.dart';
import '../maintenance/maintenance_request_list_screen.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MaintenanceRequestListScreen(),
    CreateMaintenanceRequestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Sự cố của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Gửi sự cố'),
        ],
      ),
    );
  }
}
