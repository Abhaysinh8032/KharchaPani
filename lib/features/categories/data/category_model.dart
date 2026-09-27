// lib/features/categories/data/category_model.dart
import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class Category {
  final String id, name, icon;
  final Color color;
  final CategoryType type;
  final DateTime createdAt;

  const Category({
    required this.id, required this.name, required this.icon,
    required this.color, required this.type, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'icon': icon,
    'color': color.toARGB32(), 'type': type.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id: m['id'], name: m['name'], icon: m['icon'],
    color: Color(m['color'] as int),
    type: CategoryType.values.firstWhere((e) => e.name == m['type']),
    createdAt: DateTime.parse(m['created_at']),
  );
}
