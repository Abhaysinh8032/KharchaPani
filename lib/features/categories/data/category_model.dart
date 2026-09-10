// lib/features/categories/data/category_model.dart
import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final CategoryType type;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    CategoryType? type,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color.toARGB32(),
        'type': type.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        color: Color(map['color']),
        type: CategoryType.values.firstWhere((e) => e.name == map['type']),
        createdAt: DateTime.parse(map['created_at']),
      );
}
