import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../domain/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/category_manager_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedCategoryId;

  Future<void> _editSalary() async {
    final salaryProv = context.read<SalaryProvider>();
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(
        text: salaryProv.amount > 0 ? salaryProv.amount.toStringAsFixed(2) : '');
    var currency = salaryProv.currency;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _BottomSheetWrapper(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mi Sueldo', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Monto', prefixIcon: Icon(Icons.attach_money_rounded)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: const InputDecoration(labelText: 'Moneda', prefixIcon: Icon(Icons.currency_exchange_rounded)),
                  items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setSheetState(() => currency = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx, {'amount': double.parse(amountCtrl.text), 'currency': currency});
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await salaryProv.save(result['amount'] as double, result['currency'] as String);
    }
  }

  Future<void> _addExpense() async {
    final categories = context.read<CategoryProvider>().categories;
    final expenseProv = context.read<ExpenseProvider>();
    final expense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormDialog(categories: categories),
    );
    if (expense != null) await expenseProv.add(expense);
  }

  Future<void> _editExpense(Expense expense) async {
    final categories = context.read<CategoryProvider>().categories;
    final expenseProv = context.read<ExpenseProvider>();
    final edited = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormDialog(expense: expense, categories: categories),
    );
    if (edited != null) await expenseProv.update(edited);
  }

  Future<void> _deleteExpense(Expense expense) async {
    final expenseProv = context.read<ExpenseProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${expense.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, eliminar')),
        ],
      ),
    );
    if (confirm == true) await expenseProv.remove(expense.id!);
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = context.watch<SalaryProvider>();
    final expenseProv = context.watch<ExpenseProvider>();
    final categoryProv = context.watch<CategoryProvider>();
    final cs = Theme.of(context).colorScheme;

    final filtered = _selectedCategoryId == null
        ? expenseProv.expenses
        : expenseProv.expenses.where((e) => e.categoryId == _selectedCategoryId).toList();

    final totalExpenses = filtered.where((e) => e.currency == salaryProv.currency).fold(0.0, (s, e) => s + e.amount);
    final balance = salaryProv.amount - totalExpenses;
    final pct = salaryProv.amount > 0 ? (totalExpenses / salaryProv.amount).clamp(0.0, 1.0) : 0.0;

    final usedCategoryIds = expenseProv.expenses.map((e) => e.categoryId).whereType<int>().toSet();
    final usedCategories = categoryProv.categories.where((c) => usedCategoryIds.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            title: const Text('Mis Gastos'),
            actions: [
              IconButton(icon: const Icon(Icons.category_rounded), tooltip: 'Categorías', onPressed: () => showDialog(context: context, builder: (_) => const CategoryManagerDialog())),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.7), cs.tertiary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Sueldo mensual', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _editSalary,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_rounded, size: 14, color: Colors.white), SizedBox(width: 4), Text('Editar', style: TextStyle(color: Colors.white, fontSize: 12))]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${salaryProv.currency} ${salaryProv.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.white24, color: pct > 0.8 ? Colors.redAccent : Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _headerStat('Gastos', totalExpenses, salaryProv.currency, Icons.trending_down_rounded),
                            const SizedBox(width: 24),
                            _headerStat('Disponible', balance, salaryProv.currency, Icons.account_balance_wallet_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Últimos gastos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${filtered.length} registros', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  if (usedCategories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, i1) => const SizedBox(width: 8),
                        itemCount: usedCategories.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            final selected = _selectedCategoryId == null;
                            return ChoiceChip(
                              label: const Text('Todas'),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedCategoryId = null),
                              selectedColor: cs.primary,
                              labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide.none,
                              showCheckmark: false,
                            );
                          }
                          final cat = usedCategories[i - 1];
                          final selected = _selectedCategoryId == cat.id;
                          return ChoiceChip(
                            label: Text(cat.name),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedCategoryId = selected ? null : cat.id),
                            selectedColor: cs.primary,
                            labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(_selectedCategoryId != null ? 'Sin gastos en esta categoría' : 'Sin gastos aún', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
                        const SizedBox(height: 4),
                        Text('Toca + para agregar uno', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      final catName = categoryProv.nameById(e.categoryId);
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          _deleteExpense(e);
                          return false;
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.shopping_bag_outlined, color: cs.primary, size: 22),
                            ),
                            title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${DateFormat('dd MMM yyyy').format(e.date)}${catName.isNotEmpty ? '  •  $catName' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            trailing: Text(
                              '-${e.currency} ${e.amount.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent.shade200, fontSize: 15),
                            ),
                            onTap: () => _editExpense(e),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Gasto'),
      ),
    );
  }

  Widget _headerStat(String label, double value, String currency, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  Text('$currency ${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetWrapper extends StatelessWidget {
  final Widget child;
  const _BottomSheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
