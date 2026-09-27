// lib/features/accounts/data/account_repository.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import 'account_model.dart';

class AccountRepository {
  final _db  = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Account>> getAll() async {
    final db   = await _db.database;
    final maps = await db.query('accounts', orderBy: 'created_at ASC');
    return maps.map(Account.fromMap).toList();
  }

  Future<Account?> getById(String id) async {
    final db   = await _db.database;
    final maps = await db.query('accounts', where: 'id=?', whereArgs: [id]);
    return maps.isEmpty ? null : Account.fromMap(maps.first);
  }

  Future<Account?> getByName(String name) async {
    final db   = await _db.database;
    final maps = await db.rawQuery(
      'SELECT * FROM accounts WHERE LOWER(name)=LOWER(?)', [name]);
    return maps.isEmpty ? null : Account.fromMap(maps.first);
  }

  Future<Account> create({
    required String name,
    required String icon,
    required Color color,
    double balance = 0.0,
  }) async {
    final db = await _db.database;
    final account = Account(
      id: _uuid.v4(), name: name, icon: icon,
      color: color, balance: balance, createdAt: DateTime.now(),
    );
    await db.insert('accounts', account.toMap());
    return account;
  }

  /// ✅ Edit account name, icon and color (balance unchanged)
  Future<void> edit({
    required String id,
    required String name,
    required String icon,
    required Color color,
  }) async {
    final db = await _db.database;
    await db.update('accounts',
      {'name': name, 'icon': icon, 'color': color.toARGB32()},
      where: 'id=?', whereArgs: [id]);
  }

  Future<void> updateBalance(String id, double delta) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id=?', [delta, id]);
  }

  /// Overwrite balance directly (used by import to set opening balance)
  Future<void> setBalance(String id, double balance) async {
    final db = await _db.database;
    await db.update('accounts', {'balance': balance},
      where: 'id=?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('accounts', where: 'id=?', whereArgs: [id]);
  }
}
