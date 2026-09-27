// lib/features/records/data/record_repository.dart
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../accounts/data/account_repository.dart';
import 'record_model.dart';

class RecordRepository {
  final _db       = DatabaseHelper.instance;
  final _uuid     = const Uuid();
  final _accRepo  = AccountRepository();

  static const _joinQuery = '''
    SELECT r.*,
      a.name  AS account_name,
      c.name  AS category_name,
      c.icon  AS category_icon,
      c.color AS category_color,
      ta.name AS to_account_name
    FROM records r
    LEFT JOIN accounts  a  ON r.account_id    = a.id
    LEFT JOIN categories c ON r.category_id   = c.id
    LEFT JOIN accounts  ta ON r.to_account_id = ta.id
  ''';

  Future<List<FinancialRecord>> getForMonth(int year, int month) async {
    final db    = await _db.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end   = DateTime(year, month + 1, 1).toIso8601String();
    final maps  = await db.rawQuery(
      '$_joinQuery WHERE r.date >= ? AND r.date < ? ORDER BY r.date DESC, r.created_at DESC',
      [start, end]);
    return maps.map(FinancialRecord.fromMap).toList();
  }

  Future<List<FinancialRecord>> getAll() async {
    final db   = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery ORDER BY r.date DESC, r.created_at DESC');
    return maps.map(FinancialRecord.fromMap).toList();
  }

  Future<FinancialRecord> create({
    required RecordType type,
    required double amount,
    required String accountId,
    String? categoryId, String? toAccountId, String? notes,
    required DateTime date,
    /// If true, skip balance update (used during bulk import)
    bool skipBalanceUpdate = false,
  }) async {
    final db = await _db.database;
    final record = FinancialRecord(
      id: _uuid.v4(), type: type, amount: amount,
      accountId: accountId, categoryId: categoryId,
      toAccountId: toAccountId, notes: notes,
      date: date, createdAt: DateTime.now(),
    );
    await db.insert('records', record.toMap());

    if (!skipBalanceUpdate) {
      switch (type) {
        case RecordType.expense:
          await _accRepo.updateBalance(accountId, -amount);
        case RecordType.income:
          await _accRepo.updateBalance(accountId, amount);
        case RecordType.transfer:
          if (toAccountId != null) {
            await _accRepo.updateBalance(accountId, -amount);
            await _accRepo.updateBalance(toAccountId, amount);
          }
      }
    }
    return record;
  }

  Future<void> delete(String id) async {
    final db   = await _db.database;
    final maps = await db.query('records', where: 'id=?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final r = FinancialRecord.fromMap(maps.first);
      switch (r.type) {
        case RecordType.expense:
          await _accRepo.updateBalance(r.accountId, r.amount);
        case RecordType.income:
          await _accRepo.updateBalance(r.accountId, -r.amount);
        case RecordType.transfer:
          if (r.toAccountId != null) {
            await _accRepo.updateBalance(r.accountId, r.amount);
            await _accRepo.updateBalance(r.toAccountId!, -r.amount);
          }
      }
    }
    await db.delete('records', where: 'id=?', whereArgs: [id]);
  }

  /// Delete ALL records — used during import replace
  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('records');
  }
}
