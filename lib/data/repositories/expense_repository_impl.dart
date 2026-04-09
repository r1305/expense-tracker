import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/local_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final LocalDatasource _ds;

  ExpenseRepositoryImpl(this._ds);

  @override
  Future<List<Expense>> getAll() async {
    final rows = await _ds.query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<void> insert(Expense e) async {
    await _ds.insert('expenses', e.toMap()..remove('id'));
  }

  @override
  Future<void> update(Expense e) async {
    await _ds.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  @override
  Future<void> delete(int id) async {
    await _ds.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Expense>> getByCategory(int categoryId, int year, int month) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final rows = await _ds.rawQuery(
      'SELECT * FROM expenses WHERE category_id = ? AND date >= ? AND date <= ?',
      [categoryId, start, end],
    );
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<bool> hasFixedExpenses(int fixedCategoryId, int year, int month) async {
    final list = await getByCategory(fixedCategoryId, year, month);
    return list.isNotEmpty;
  }
}
