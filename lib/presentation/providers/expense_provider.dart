import 'package:flutter/foundation.dart';

import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseRepository _repo;

  List<Expense> expenses = [];

  ExpenseProvider(this._repo);

  void updateRepository(ExpenseRepository repo) {
    _repo = repo;
    load();
  }

  Future<void> load() async {
    expenses = await _repo.getAll();
    notifyListeners();
  }

  Future<void> add(Expense e) async {
    await _repo.insert(e);
    await load();
  }

  Future<void> update(Expense e) async {
    await _repo.update(e);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }

  double totalByCurrency(String currency) =>
      expenses.where((e) => e.currency == currency).fold(0, (s, e) => s + e.amount);

  Future<void> carryOverFixed(int fixedCategoryId) async {
    final now = DateTime.now();
    final alreadyExists = await _repo.hasFixedExpenses(fixedCategoryId, now.year, now.month);
    if (alreadyExists) return;

    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final previous = await _repo.getByCategory(fixedCategoryId, prevMonth.year, prevMonth.month);
    if (previous.isEmpty) return;

    final firstOfMonth = DateTime(now.year, now.month, 1);
    for (final e in previous) {
      await _repo.insert(Expense(
        description: e.description,
        amount: e.amount,
        currency: e.currency,
        date: firstOfMonth,
        categoryId: fixedCategoryId,
      ));
    }
    await load();
  }
}
