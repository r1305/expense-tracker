import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/remote_datasource.dart';

class ExpenseRepositoryRemoteImpl implements ExpenseRepository {
  final RemoteDatasource _ds;

  ExpenseRepositoryRemoteImpl(this._ds);

  @override
  Future<List<Expense>> getAll() async {
    final list = await _ds.getList('expenses');
    return list
        .map((e) => Expense.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> insert(Expense e) async {
    await _ds.post('expenses', e.toMap()..remove('id'));
  }

  @override
  Future<void> update(Expense e) async {
    await _ds.put('expenses/${e.id}', e.toMap());
  }

  @override
  Future<void> delete(int id) async {
    await _ds.delete('expenses/$id');
  }
}
