import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/salary_provider.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  static const _colors = [
    Colors.teal,
    Colors.orange,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.deepPurple,
    Colors.lightGreen,
    Colors.redAccent,
    Colors.blueGrey,
  ];

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categoryProv = context.watch<CategoryProvider>();
    final currency = context.watch<SalaryProvider>().currency;

    final filtered = expenses.where((e) =>
        e.currency == currency &&
        e.date.month == _selectedMonth &&
        e.date.year == _selectedYear);

    final Map<int?, double> totals = {};
    for (final e in filtered) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }

    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos por Categoría')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_monthNames[i]),
                    )),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
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
          Expanded(
            child: grandTotal == 0
                ? const Center(child: Text('No hay gastos en este período'))
                : Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: List.generate(entries.length, (i) {
                              final e = entries[i];
                              final pct = e.value / grandTotal * 100;
                              return PieChartSectionData(
                                value: e.value,
                                color: _colors[i % _colors.length],
                                title: '${pct.toStringAsFixed(1)}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Total: $currency ${grandTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: entries.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (_, i) {
                            final e = entries[i];
                            final name = categoryProv.nameById(e.key);
                            final pct = e.value / grandTotal * 100;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _colors[i % _colors.length],
                                radius: 8,
                              ),
                              title: Text(name.isEmpty ? 'Sin categoría' : name),
                              trailing: Text(
                                '$currency ${e.value.toStringAsFixed(2)}  (${pct.toStringAsFixed(1)}%)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
