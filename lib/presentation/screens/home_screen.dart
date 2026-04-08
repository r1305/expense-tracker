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
import '../screens/settings_screen.dart';
import '../screens/chart_screen.dart';
import '../screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final salaryProv = context.read<SalaryProvider>();
    final expenseProv = context.read<ExpenseProvider>();
    final categoryProv = context.read<CategoryProvider>();
    await Future.wait([
      salaryProv.load(),
      expenseProv.load(),
      categoryProv.load(),
    ]);
  }

  Future<void> _editSalary() async {
    final salaryProv = context.read<SalaryProvider>();
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(
        text: salaryProv.amount > 0 ? salaryProv.amount.toStringAsFixed(2) : '');
    var currency = salaryProv.currency;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mi Sueldo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Monto *'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                  items: currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => currency = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx, {
                  'amount': double.parse(amountCtrl.text),
                  'currency': currency
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await salaryProv.save(
          result['amount'] as double, result['currency'] as String);
    }
  }

  Future<void> _manageCategories() async {
    await showDialog(
      context: context,
      builder: (_) => const CategoryManagerDialog(),
    );
  }

  Future<void> _addExpense() async {
    final categories = context.read<CategoryProvider>().categories;
    final expenseProv = context.read<ExpenseProvider>();
    final expense = await showDialog<Expense>(
      context: context,
      builder: (_) => ExpenseFormDialog(categories: categories),
    );
    if (expense != null) {
      await expenseProv.add(expense);
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final categories = context.read<CategoryProvider>().categories;
    final expenseProv = context.read<ExpenseProvider>();
    final edited = await showDialog<Expense>(
      context: context,
      builder: (_) =>
          ExpenseFormDialog(expense: expense, categories: categories),
    );
    if (edited != null) {
      await expenseProv.update(edited);
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final expenseProv = context.read<ExpenseProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${expense.description}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (confirm == true) {
      await expenseProv.remove(expense.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salaryProv = context.watch<SalaryProvider>();
    final expenseProv = context.watch<ExpenseProvider>();
    final categoryProv = context.watch<CategoryProvider>();

    final totalExpenses = expenseProv.totalByCurrency(salaryProv.currency);
    final balance = salaryProv.amount - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Resumen',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Categorías',
            onPressed: _manageCategories,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sueldo', style: theme.textTheme.bodySmall),
                          Text(
                            '${salaryProv.currency} ${salaryProv.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _editSalary,
                        tooltip: 'Editar sueldo',
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryItem('Gastos', totalExpenses, Colors.red,
                          salaryProv.currency),
                      _summaryItem(
                          'Saldo',
                          balance,
                          balance >= 0 ? Colors.green : Colors.red,
                          salaryProv.currency),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: expenseProv.expenses.isEmpty
                ? const Center(child: Text('No hay gastos registrados'))
                : ListView.builder(
                    itemCount: expenseProv.expenses.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (_, i) {
                      final e = expenseProv.expenses[i];
                      final catName = categoryProv.nameById(e.categoryId);
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red,
                          child:
                              const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          _deleteExpense(e);
                          return false;
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(e.description),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy').format(e.date)}'
                              '${catName.isNotEmpty ? '  •  $catName' : ''}',
                            ),
                            trailing: Text(
                              '${e.currency} ${e.amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.red),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryItem(
      String label, double value, Color color, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '$currency ${value.toStringAsFixed(2)}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
