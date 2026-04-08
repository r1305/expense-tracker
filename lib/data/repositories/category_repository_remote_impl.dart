import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/remote_datasource.dart';

class CategoryRepositoryRemoteImpl implements CategoryRepository {
  final RemoteDatasource _ds;

  CategoryRepositoryRemoteImpl(this._ds);

  @override
  Future<List<Category>> getAll() async {
    final list = await _ds.getList('categories');
    return list
        .map((e) => Category.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> insert(Category c) async {
    await _ds.post('categories', {'name': c.name});
  }

  @override
  Future<void> update(Category c) async {
    await _ds.put('categories/${c.id}', c.toMap());
  }

  @override
  Future<void> delete(int id) async {
    await _ds.delete('categories/$id');
  }
}
