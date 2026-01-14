import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/portfolio_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider를 사용하여 여러 상태를 관리할 준비를 합니다.
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PortfolioProvider())],
      child: MaterialApp(
        title: 'Asset Dashboard',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const DashboardScreen(),
      ),
    );
  }
}
