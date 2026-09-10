// lib/features/records/data/record_model.dart

enum RecordType { income, expense, transfer }

class FinancialRecord {
  final String id;
  final RecordType type;
  final double amount;
  final String accountId;
  final String? categoryId;
  final String? toAccountId; // for transfers
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  // Joined fields (not stored)
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;
  final String? toAccountName;

  const FinancialRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    this.notes,
    required this.date,
    required this.createdAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.toAccountName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'account_id': accountId,
        'category_id': categoryId,
        'to_account_id': toAccountId,
        'notes': notes,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory FinancialRecord.fromMap(Map<String, dynamic> map) => FinancialRecord(
        id: map['id'],
        type: RecordType.values.firstWhere((e) => e.name == map['type']),
        amount: map['amount'],
        accountId: map['account_id'],
        categoryId: map['category_id'],
        toAccountId: map['to_account_id'],
        notes: map['notes'],
        date: DateTime.parse(map['date']),
        createdAt: DateTime.parse(map['created_at']),
        accountName: map['account_name'],
        categoryName: map['category_name'],
        categoryIcon: map['category_icon'],
        categoryColor: map['category_color'],
        toAccountName: map['to_account_name'],
      );
}
