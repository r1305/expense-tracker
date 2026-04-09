import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getAll();
  Future<void> insert(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(int id);
  Future<List<Expense>> getByCategory(int categoryId, int year, int month);
  Future<bool> hasFixedExpenses(int fixedCategoryId, int year, int month);
}
