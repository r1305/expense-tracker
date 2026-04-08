import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getAll();
  Future<void> insert(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(int id);
}
