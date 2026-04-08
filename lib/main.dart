import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local_datasource.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/salary_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ds = LocalDatasource();
  final settingsProvider = SettingsProvider(ds);
  await settingsProvider.init();

  final expenseRepo = settingsProvider.expenseRepository;
  final categoryRepo = settingsProvider.categoryRepository;
  final salaryRepo = settingsProvider.salaryRepository;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => SalaryProvider(salaryRepo)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(expenseRepo)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(categoryRepo)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
