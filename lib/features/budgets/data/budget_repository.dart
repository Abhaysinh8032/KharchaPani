// lib/features/budgets/data/budget_repository.dart
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import 'budget_model.dart';

class BudgetRepository {
  final _db   = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Budget>> getForMonth(int year, int month) async {
    final db    = await _db.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end   = DateTime(year, month + 1, 1).toIso8601String();
    final maps  = await db.rawQuery('''
      SELECT b.*, c.name AS category_name, c.icon AS category_icon,
             c.color AS category_color,
             COALESCE((SELECT SUM(r.amount) FROM records r
               WHERE r.category_id = b.category_id
               AND r.type = 'expense'
               AND r.date >= ? AND r.date < ?), 0) AS spent
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.year=? AND b.month=?
      ORDER BY c.name ASC
    ''', [start, end, year, month]);
    return maps.map(Budget.fromMap).toList();
  }

  Future<List<String>> getBudgetedCategoryIds(int year, int month) async {
    final db   = await _db.database;
    final maps = await db.query('budgets',
      columns: ['category_id'],
      where: 'year=? AND month=?', whereArgs: [year, month]);
    return maps.map((m) => m['category_id'] as String).toList();
  }

  Future<void> create({
    required String categoryId,
    required double amount,
    required int year, required int month,
  }) async {
    final db = await _db.database;
    await db.insert('budgets', Budget(
      id: _uuid.v4(), categoryId: categoryId, amount: amount,
      month: month, year: year, createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> update(String id, double amount) async {
    final db = await _db.database;
    await db.update('budgets', {'amount': amount},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
