import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final LocalDatasource _ds;

  CategoryRepositoryImpl(this._ds);

  @override
  Future<List<Category>> getAll() async {
    final rows = await _ds.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<void> insert(Category c) async {
    await _ds.insert('categories', {'name': c.name});
  }

  @override
  Future<void> update(Category c) async {
    await _ds.update('categories', {'name': c.name},
        where: 'id = ?', whereArgs: [c.id]);
  }

  @override
  Future<void> delete(int id) async {
    await _ds.update('expenses', {'category_id': null},
        where: 'category_id = ?', whereArgs: [id]);
    await _ds.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
