// lib/features/budgets/data/budget_model.dart

class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final int month;
  final int year;
  final DateTime createdAt;

  // Joined
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;
  final double? spent;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.spent,
  });

  double get remaining => amount - (spent ?? 0);
  double get spentPercent => amount > 0 ? ((spent ?? 0) / amount).clamp(0, 1) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
        'created_at': createdAt.toIso8601String(),
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'],
        categoryId: map['category_id'],
        amount: map['amount'],
        month: map['month'],
        year: map['year'],
        createdAt: DateTime.parse(map['created_at']),
        categoryName: map['category_name'],
        categoryIcon: map['category_icon'],
        categoryColor: map['category_color'],
        spent: map['spent'] != null ? (map['spent'] as num).toDouble() : null,
      );
}
