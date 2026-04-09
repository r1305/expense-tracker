import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/category_provider.dart';
import 'home_screen.dart';
import 'chart_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    ChartScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    final salaryProv = context.read<SalaryProvider>();
    final expenseProv = context.read<ExpenseProvider>();
    final categoryProv = context.read<CategoryProvider>();
    await Future.wait([
      salaryProv.load(),
      expenseProv.load(),
      categoryProv.load(),
    ]);
    final fixedId = categoryProv.fixedCategoryId;
    if (fixedId != null) {
      await expenseProv.carryOverFixed(fixedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded), selectedIcon: Icon(Icons.pie_chart_rounded), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}
