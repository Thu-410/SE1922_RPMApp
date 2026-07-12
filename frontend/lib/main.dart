import 'package:flutter/material.dart';

import 'screens/tenants/tenant_list_screen.dart';
import 'screens/contracts/contract_list_screen.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Order Food',

      home: const ContractListScreen(),
    );
  }
}
