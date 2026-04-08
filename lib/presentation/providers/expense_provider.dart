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
}
