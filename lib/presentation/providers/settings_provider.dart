import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/expense_repository_remote_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/category_repository_remote_impl.dart';
import '../../data/repositories/salary_repository_impl.dart';
import '../../data/repositories/salary_repository_remote_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/salary_repository.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyLocalhost = 'localhost';
  static const _keyBaseUrl = 'base_url';

  final LocalDatasource _localDs;
  late SharedPreferences _prefs;

  bool _isLocalhost = true;
  String _baseUrl = '';
  bool _syncing = false;

  bool get isLocalhost => _isLocalhost;
  String get baseUrl => _baseUrl;
  bool get syncing => _syncing;

  SettingsProvider(this._localDs);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isLocalhost = _prefs.getBool(_keyLocalhost) ?? true;
    _baseUrl = _prefs.getString(_keyBaseUrl) ?? '';
    notifyListeners();
  }

  Future<void> setLocalhost(bool value) async {
    _isLocalhost = value;
    await _prefs.setBool(_keyLocalhost, value);
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await _prefs.setString(_keyBaseUrl, url);
    notifyListeners();
  }

  ExpenseRepository get expenseRepository => _isLocalhost
      ? ExpenseRepositoryImpl(_localDs)
      : ExpenseRepositoryRemoteImpl(RemoteDatasource(baseUrl: _baseUrl));

  CategoryRepository get categoryRepository => _isLocalhost
      ? CategoryRepositoryImpl(_localDs)
      : CategoryRepositoryRemoteImpl(RemoteDatasource(baseUrl: _baseUrl));

  SalaryRepository get salaryRepository => _isLocalhost
      ? SalaryRepositoryImpl(_localDs)
      : SalaryRepositoryRemoteImpl(RemoteDatasource(baseUrl: _baseUrl));

  Future<String> syncToCloud() async {
    if (_baseUrl.isEmpty) return 'Configura la URL del servidor primero';
    _syncing = true;
    notifyListeners();

    try {
      final remote = RemoteDatasource(baseUrl: _baseUrl);
      final localExpenses = ExpenseRepositoryImpl(_localDs);
      final localCategories = CategoryRepositoryImpl(_localDs);
      final localSalary = SalaryRepositoryImpl(_localDs);

      final remoteExpenses = ExpenseRepositoryRemoteImpl(remote);
      final remoteCategories = CategoryRepositoryRemoteImpl(remote);
      final remoteSalary = SalaryRepositoryRemoteImpl(remote);

      // Sync categories
      final categories = await localCategories.getAll();
      for (final c in categories) {
        await remoteCategories.insert(c);
      }

      // Sync expenses
      final expenses = await localExpenses.getAll();
      for (final e in expenses) {
        await remoteExpenses.insert(e);
      }

      // Sync salary
      final salary = await localSalary.get();
      if (salary != null) {
        await remoteSalary.set(
          (salary['amount'] as num).toDouble(),
          salary['currency'] as String,
        );
      }

      return 'Sincronización completada';
    } catch (e) {
      return 'Error al sincronizar: $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }
}
