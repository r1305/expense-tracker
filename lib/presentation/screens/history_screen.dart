import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/salary_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  int? _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  List<Expense> _filter(List<Expense> expenses, String currency) {
    return expenses.where((e) {
      if (e.currency != currency) return false;
      if (e.date.year != _selectedYear) return false;
      if (_selectedMonth != null && e.date.month != _selectedMonth) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String get _periodLabel {
    if (_selectedMonth != null) {
      return '${_monthNames[_selectedMonth! - 1]} $_selectedYear';
    }
    return 'Año $_selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categoryProv = context.watch<CategoryProvider>();
    final currency = context.watch<SalaryProvider>().currency;
    final theme = Theme.of(context);

    final filtered = _filter(expenses, currency);
    final total = filtered.fold(0.0, (s, e) => s + e.amount);

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...List.generate(12, (i) => DropdownMenuItem<int?>(
                        value: i + 1,
                        child: Text(_monthNames[i]),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedMonth = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((y) => DropdownMenuItem(
                      value: y,
                      child: Text('$y'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Acumulado', style: theme.textTheme.bodySmall),
                      Text(
                        _periodLabel,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    '$currency ${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No hay gastos en este período'))
                : ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      final catName = categoryProv.nameById(e.categoryId);
                      return Card(
                        child: ListTile(
                          title: Text(e.description),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(e.date)}'
                            '${catName.isNotEmpty ? '  •  $catName' : ''}',
                          ),
                          trailing: Text(
                            '$currency ${e.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
