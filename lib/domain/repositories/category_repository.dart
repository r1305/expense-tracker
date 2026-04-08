import '../models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<void> insert(Category category);
  Future<void> update(Category category);
  Future<void> delete(int id);
}
