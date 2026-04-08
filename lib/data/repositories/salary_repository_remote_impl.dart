import '../../domain/repositories/salary_repository.dart';
import '../datasources/remote_datasource.dart';

class SalaryRepositoryRemoteImpl implements SalaryRepository {
  final RemoteDatasource _ds;

  SalaryRepositoryRemoteImpl(this._ds);

  @override
  Future<Map<String, dynamic>?> get() async {
    return _ds.getOne('salary');
  }

  @override
  Future<void> set(double amount, String currency) async {
    await _ds.put('salary', {'amount': amount, 'currency': currency});
  }
}
