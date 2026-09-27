// lib/features/budgets/data/budget_model.dart
class Budget {
  final String id, categoryId;
  final double amount;
  final int month, year;
  final DateTime createdAt;

  final String? categoryName, categoryIcon;
  final int? categoryColor;
  final double? spent;

  const Budget({
    required this.id, required this.categoryId, required this.amount,
    required this.month, required this.year, required this.createdAt,
    this.categoryName, this.categoryIcon, this.categoryColor, this.spent,
  });

  double get remaining    => amount - (spent ?? 0);
  double get spentPercent => amount > 0 ? ((spent ?? 0) / amount).clamp(0.0, 1.0) : 0;
  bool   get isOver       => (spent ?? 0) > amount;

  Map<String, dynamic> toMap() => {
    'id': id, 'category_id': categoryId, 'amount': amount,
    'month': month, 'year': year,
    'created_at': createdAt.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
    id: m['id'], categoryId: m['category_id'],
    amount: (m['amount'] as num).toDouble(),
    month: m['month'] as int, year: m['year'] as int,
    createdAt: DateTime.parse(m['created_at']),
    categoryName: m['category_name'],
    categoryIcon: m['category_icon'],
    categoryColor: m['category_color'] as int?,
    spent: m['spent'] != null ? (m['spent'] as num).toDouble() : null,
  );
}
