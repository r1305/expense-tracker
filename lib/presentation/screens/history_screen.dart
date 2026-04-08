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
  static const _months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  int? _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  List<Expense> _filter(List<Expense> expenses, String currency) {
    return expenses.where((e) {
      if (e.currency != currency || e.date.year != _year) return false;
      if (_month != null && e.date.month != _month) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categoryProv = context.watch<CategoryProvider>();
    final currency = context.watch<SalaryProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    final filtered = _filter(expenses, currency);
    final total = filtered.fold(0.0, (s, e) => s + e.amount);

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    // Group by date
    final Map<String, List<Expense>> grouped = {};
    for (final e in filtered) {
      final key = DateFormat('dd MMM yyyy').format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Historial', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, i1) => const SizedBox(width: 8),
                itemCount: 13,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final selected = _month == null;
                    return ChoiceChip(
                      label: const Text('Todo'),
                      selected: selected,
                      onSelected: (_) => setState(() => _month = null),
                      selectedColor: cs.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                      showCheckmark: false,
                    );
                  }
                  final m = i;
                  final selected = m == _month;
                  return ChoiceChip(
                    label: Text(_months[m - 1]),
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
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total acumulado', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        _month != null ? '${_months[_month! - 1]} $_year' : 'Año $_year',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '$currency ${total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Sin gastos en este período', style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final date = grouped.keys.elementAt(i);
                        final items = grouped[date]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                              child: Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                            ),
                            ...items.map((e) {
                              final catName = categoryProv.nameById(e.categoryId);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                                      child: Icon(Icons.receipt_outlined, color: cs.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          if (catName.isNotEmpty) Text(catName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '-$currency ${e.amount.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent.shade200, fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
