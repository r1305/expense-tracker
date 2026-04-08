class Expense {
  final int? id;
  final String description;
  final double amount;
  final String currency;
  final DateTime date;
  final int? categoryId;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
    this.categoryId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'category_id': categoryId,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        date: DateTime.parse(map['date'] as String),
        categoryId: map['category_id'] as int?,
      );

  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    String? currency,
    DateTime? date,
    int? categoryId,
  }) =>
      Expense(
        id: id ?? this.id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        date: date ?? this.date,
        categoryId: categoryId ?? this.categoryId,
      );
}
