// lib/features/categories/data/category_repository.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import 'category_model.dart';

class CategoryRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<List<Category>> getByType(CategoryType type) async {
    final db = await _db.database;
    final maps = await db.query('categories',
        where: 'type = ?', whereArgs: [type.name], orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await _db.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<Category> create({
    required String name,
    required String icon,
    required Color color,
    required CategoryType type,
  }) async {
    final db = await _db.database;
    final category = Category(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      type: type,
      createdAt: DateTime.now(),
    );
    await db.insert('categories', category.toMap());
    return category;
  }

  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
