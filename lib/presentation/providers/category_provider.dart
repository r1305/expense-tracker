import 'package:flutter/foundation.dart' hide Category;

import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryRepository _repo;

  List<Category> categories = [];

  CategoryProvider(this._repo);

  void updateRepository(CategoryRepository repo) {
    _repo = repo;
    load();
  }

  int? get fixedCategoryId {
    final match = categories.where((c) => c.fixed);
    return match.isNotEmpty ? match.first.id : null;
  }

  bool isFixed(int? id) => id != null && id == fixedCategoryId;

  Future<void> load() async {
    categories = await _repo.getAll();
    notifyListeners();
  }

  Future<void> add(Category c) async {
    await _repo.insert(c);
    await load();
  }

  Future<void> update(Category c) async {
    await _repo.update(c);
    await load();
  }

  Future<void> remove(int id) async {
    if (isFixed(id)) return;
    await _repo.delete(id);
    await load();
  }

  String nameById(int? id) {
    if (id == null) return '';
    final match = categories.where((c) => c.id == id);
    return match.isNotEmpty ? match.first.name : '';
  }
}
