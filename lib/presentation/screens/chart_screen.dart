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
    Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFF43E97B),
    Color(0xFFFA709A), Color(0xFFFEE140), Color(0xFF30CFD0),
    Color(0xFFA18CD1), Color(0xFFFBC2EB), Color(0xFFFF9A9E), Color(0xFF667EEA),
  ];

  static const _months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  late int _month;
  late int _year;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categoryProv = context.watch<CategoryProvider>();
    final currency = context.watch<SalaryProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    final filtered = expenses.where((e) => e.currency == currency && e.date.month == _month && e.date.year == _year);
    final Map<int?, double> totals = {};
    for (final e in filtered) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Resumen', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, i1) => const SizedBox(width: 8),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final selected = m == _month;
                  return ChoiceChip(
                    label: Text(_months[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _month = m),
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, i2) => const SizedBox(width: 8),
                itemCount: years.length,
                itemBuilder: (_, i) {
                  final y = years[i];
                  final selected = y == _year;
                  return ChoiceChip(
                    label: Text('$y'),
                    selected: selected,
                    onSelected: (_) => setState(() => _year = y),
                    selectedColor: cs.tertiary,
                    labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    showCheckmark: false,
                  );
                },
              ),
            ),
            Expanded(
              child: grandTotal == 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.donut_large_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Sin datos para este período', style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    _touchedIndex = (!event.isInterestedForInteractions || response == null || response.touchedSection == null)
                                        ? -1
                                        : response.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 3,
                              centerSpaceRadius: 50,
                              sections: List.generate(entries.length, (i) {
                                final e = entries[i];
                                final pct = e.value / grandTotal * 100;
                                final isTouched = i == _touchedIndex;
                                return PieChartSectionData(
                                  value: e.value,
                                  color: _colors[i % _colors.length],
                                  title: '${pct.toStringAsFixed(0)}%',
                                  radius: isTouched ? 70 : 55,
                                  titleStyle: TextStyle(fontSize: isTouched ? 14 : 11, fontWeight: FontWeight.bold, color: Colors.white),
                                );
                              }),
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('$currency ${grandTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: entries.length,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            separatorBuilder: (_, i3) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final e = entries[i];
                              final name = categoryProv.nameById(e.key);
                              final pct = e.value / grandTotal * 100;
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    Container(width: 12, height: 12, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(name.isEmpty ? 'Sin categoría' : name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('$currency ${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ],
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
      ),
    );
  }
}
