// lib/features/categories/data/category_repository.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import 'category_model.dart';

class CategoryRepository {
  final _db   = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    return (await db.query('categories', orderBy: 'name ASC'))
        .map(Category.fromMap).toList();
  }

  Future<List<Category>> getByType(CategoryType type) async {
    final db = await _db.database;
    return (await db.query('categories',
        where: 'type=?', whereArgs: [type.name], orderBy: 'name ASC'))
        .map(Category.fromMap).toList();
  }

  Future<Category?> getByName(String name) async {
    final db   = await _db.database;
    final maps = await db.rawQuery(
      'SELECT * FROM categories WHERE LOWER(name)=LOWER(?)', [name]);
    return maps.isEmpty ? null : Category.fromMap(maps.first);
  }

  Future<Category> create({
    required String name, required String icon,
    required Color color, required CategoryType type,
  }) async {
    final db = await _db.database;
    final cat = Category(
      id: _uuid.v4(), name: name, icon: icon,
      color: color, type: type, createdAt: DateTime.now(),
    );
    await db.insert('categories', cat.toMap());
    return cat;
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id=?', whereArgs: [id]);
  }
}
