import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../domain/repositories/salary_repository.dart';
import '../datasources/local_datasource.dart';

class SalaryRepositoryImpl implements SalaryRepository {
  final LocalDatasource _ds;

  SalaryRepositoryImpl(this._ds);

  @override
  Future<Map<String, dynamic>?> get() async {
    final rows =
        await _ds.query('salary', where: 'id = 1');
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> set(double amount, String currency) async {
    await _ds.insert(
      'salary',
      {'id': 1, 'amount': amount, 'currency': currency},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
