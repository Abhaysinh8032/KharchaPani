// lib/features/records/data/record_repository.dart
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../accounts/data/account_repository.dart';
import 'record_model.dart';

class RecordRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();
  final _accountRepo = AccountRepository();

  Future<List<FinancialRecord>> getForMonth(int year, int month) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    final maps = await db.rawQuery('''
      SELECT 
        r.*,
        a.name as account_name,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color,
        ta.name as to_account_name
      FROM records r
      LEFT JOIN accounts a ON r.account_id = a.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN accounts ta ON r.to_account_id = ta.id
      WHERE r.date >= ? AND r.date < ?
      ORDER BY r.date DESC, r.created_at DESC
    ''', [start, end]);

    return maps.map(FinancialRecord.fromMap).toList();
  }

  Future<List<FinancialRecord>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT 
        r.*,
        a.name as account_name,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color,
        ta.name as to_account_name
      FROM records r
      LEFT JOIN accounts a ON r.account_id = a.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN accounts ta ON r.to_account_id = ta.id
      ORDER BY r.date DESC, r.created_at DESC
    ''');
    return maps.map(FinancialRecord.fromMap).toList();
  }

  Future<FinancialRecord> create({
    required RecordType type,
    required double amount,
    required String accountId,
    String? categoryId,
    String? toAccountId,
    String? notes,
    required DateTime date,
  }) async {
    // Validate account exists
    final account = await _accountRepo.getById(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }

    // Validate toAccount for transfers
    if (type == RecordType.transfer) {
      if (toAccountId == null) {
        throw Exception('Transfer requires toAccountId');
      }
      final toAccount = await _accountRepo.getById(toAccountId);
      if (toAccount == null) {
        throw Exception('To account not found: $toAccountId');
      }
    }

    final db = await _db.database;
    final record = FinancialRecord(
      id: _uuid.v4(),
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      toAccountId: toAccountId,
      notes: notes,
      date: date,
      createdAt: DateTime.now(),
    );
    await db.insert('records', record.toMap());

    // Update account balances
    if (type == RecordType.expense) {
      await _accountRepo.updateBalance(accountId, -amount);
    } else if (type == RecordType.income) {
      await _accountRepo.updateBalance(accountId, amount);
    } else if (type == RecordType.transfer && toAccountId != null) {
      await _accountRepo.updateBalance(accountId, -amount);
      await _accountRepo.updateBalance(toAccountId, amount);
    }

    return record;
  }

  Future<void> update({
    required String id,
    required RecordType type,
    required double amount,
    required String accountId,
    String? categoryId,
    String? toAccountId,
    String? notes,
    required DateTime date,
  }) async {
    // Validate account exists
    final account = await _accountRepo.getById(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }

    // Validate toAccount for transfers
    if (type == RecordType.transfer) {
      if (toAccountId == null) {
        throw Exception('Transfer requires toAccountId');
      }
      final toAccount = await _accountRepo.getById(toAccountId);
      if (toAccount == null) {
        throw Exception('To account not found: $toAccountId');
      }
    }

    final db = await _db.database;

    // Get old record to reverse its balance effect
    final oldMaps = await db.query('records', where: 'id = ?', whereArgs: [id]);
    if (oldMaps.isEmpty) return;

    final oldRecord = FinancialRecord.fromMap(oldMaps.first);

    // Reverse old balance changes
    if (oldRecord.type == RecordType.expense) {
      await _accountRepo.updateBalance(oldRecord.accountId, oldRecord.amount);
    } else if (oldRecord.type == RecordType.income) {
      await _accountRepo.updateBalance(oldRecord.accountId, -oldRecord.amount);
    } else if (oldRecord.type == RecordType.transfer &&
        oldRecord.toAccountId != null) {
      await _accountRepo.updateBalance(oldRecord.accountId, oldRecord.amount);
      await _accountRepo.updateBalance(
          oldRecord.toAccountId!, -oldRecord.amount);
    }

    // Update record
    final record = FinancialRecord(
      id: id,
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      toAccountId: toAccountId,
      notes: notes,
      date: date,
      createdAt: oldRecord.createdAt,
    );

    await db
        .update('records', record.toMap(), where: 'id = ?', whereArgs: [id]);

    // Apply new balance changes
    if (type == RecordType.expense) {
      await _accountRepo.updateBalance(accountId, -amount);
    } else if (type == RecordType.income) {
      await _accountRepo.updateBalance(accountId, amount);
    } else if (type == RecordType.transfer && toAccountId != null) {
      await _accountRepo.updateBalance(accountId, -amount);
      await _accountRepo.updateBalance(toAccountId, amount);
    }
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    // Get record first to reverse balance effect
    final maps = await db.query('records', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final record = FinancialRecord.fromMap(maps.first);
      if (record.type == RecordType.expense) {
        await _accountRepo.updateBalance(record.accountId, record.amount);
      } else if (record.type == RecordType.income) {
        await _accountRepo.updateBalance(record.accountId, -record.amount);
      } else if (record.type == RecordType.transfer &&
          record.toAccountId != null) {
        await _accountRepo.updateBalance(record.accountId, record.amount);
        await _accountRepo.updateBalance(record.toAccountId!, -record.amount);
      }
    }
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getCategorySummaryForMonth(
      int year, int month) async {
    final db = await _db.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();

    final maps = await db.rawQuery('''
      SELECT c.name, SUM(r.amount) as total
      FROM records r
      LEFT JOIN categories c ON r.category_id = c.id
      WHERE r.date >= ? AND r.date < ? AND r.type = 'expense'
      GROUP BY r.category_id
      ORDER BY total DESC
    ''', [start, end]);

    return {
      for (final m in maps)
        (m['name'] as String? ?? 'Uncategorized'):
            (m['total'] as num).toDouble()
    };
  }
}
