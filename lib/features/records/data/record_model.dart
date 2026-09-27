// lib/features/records/data/record_model.dart
enum RecordType { income, expense, transfer }

class FinancialRecord {
  final String id;
  final RecordType type;
  final double amount;
  final String accountId;
  final String? categoryId, toAccountId, notes;
  final DateTime date, createdAt;

  // Joined display fields
  final String? accountName, categoryName, categoryIcon, toAccountName;
  final int? categoryColor;

  const FinancialRecord({
    required this.id, required this.type, required this.amount,
    required this.accountId, this.categoryId, this.toAccountId,
    this.notes, required this.date, required this.createdAt,
    this.accountName, this.categoryName, this.categoryIcon,
    this.categoryColor, this.toAccountName,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'type': type.name, 'amount': amount,
    'account_id': accountId, 'category_id': categoryId,
    'to_account_id': toAccountId, 'notes': notes,
    'date': date.toIso8601String(), 'created_at': createdAt.toIso8601String(),
  };

  factory FinancialRecord.fromMap(Map<String, dynamic> m) => FinancialRecord(
    id: m['id'], type: RecordType.values.firstWhere((e) => e.name == m['type']),
    amount: (m['amount'] as num).toDouble(),
    accountId: m['account_id'],
    categoryId: m['category_id'],
    toAccountId: m['to_account_id'],
    notes: m['notes'],
    date: DateTime.parse(m['date']),
    createdAt: DateTime.parse(m['created_at']),
    accountName: m['account_name'],
    categoryName: m['category_name'],
    categoryIcon: m['category_icon'],
    categoryColor: m['category_color'] as int?,
    toAccountName: m['to_account_name'],
  );
}
