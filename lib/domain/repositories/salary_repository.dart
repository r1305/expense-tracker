abstract class SalaryRepository {
  Future<Map<String, dynamic>?> get();
  Future<void> set(double amount, String currency);
}
