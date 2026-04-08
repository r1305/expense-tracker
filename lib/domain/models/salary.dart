class Salary {
  final int? id;
  final double amount;
  final String currency;

  Salary({this.id, required this.amount, required this.currency});

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'currency': currency,
      };

  factory Salary.fromMap(Map<String, dynamic> map) => Salary(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
      );
}
