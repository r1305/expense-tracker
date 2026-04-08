import 'package:flutter/foundation.dart';

import '../../domain/repositories/salary_repository.dart';

class SalaryProvider extends ChangeNotifier {
  SalaryRepository _repo;

  double amount = 0;
  String currency = 'PEN';

  SalaryProvider(this._repo);

  void updateRepository(SalaryRepository repo) {
    _repo = repo;
    load();
  }

  Future<void> load() async {
    final data = await _repo.get();
    if (data != null) {
      amount = (data['amount'] as num).toDouble();
      currency = data['currency'] as String;
    }
    notifyListeners();
  }

  Future<void> save(double newAmount, String newCurrency) async {
    await _repo.set(newAmount, newCurrency);
    amount = newAmount;
    currency = newCurrency;
    notifyListeners();
  }
}
