// lib/features/accounts/data/account_repository.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import 'account_model.dart';

class AccountRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Account>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('accounts', orderBy: 'created_at ASC');
    return maps.map(Account.fromMap).toList();
  }

  Future<Account?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<void> insert(Account account) async {
    final db = await _db.database;
    await db.insert('accounts', account.toMap());
  }

  Future<Account> create({
    required String name,
    required String icon,
    required int colorValue,
    double balance = 0.0,
  }) async {
    final account = Account(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: Color(colorValue),
      balance: balance,
      createdAt: DateTime.now(),
    );
    await insert(account);
    return account;
  }

  Future<void> update(Account account) async {
    final db = await _db.database;
    await db.update('accounts', account.toMap(),
        where: 'id = ?', whereArgs: [account.id]);
  }

  Future<void> updateBalance(String id, double delta) async {
    final db = await _db.database;
    await db.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?', [delta, id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}
