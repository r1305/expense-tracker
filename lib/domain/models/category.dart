class Category {
  final int? id;
  final String name;
  final bool fixed;

  Category({this.id, required this.name, this.fixed = false});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'fixed': fixed ? 1 : 0};

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int,
        name: map['name'] as String,
        fixed: (map['fixed'] as int?) == 1,
      );
}
