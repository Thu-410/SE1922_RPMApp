import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../maintenance/maintenance_request_list_screen.dart';
import '../reports/debt_report_screen.dart';
import '../reports/occupancy_report_screen.dart';
import '../reports/revenue_report_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MaintenanceRequestListScreen(),
    RevenueReportScreen(),
    DebtReportScreen(),
    OccupancyReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Sự cố'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Doanh thu'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Công nợ'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Phòng'),
        ],
      ),
    );
  }
}
