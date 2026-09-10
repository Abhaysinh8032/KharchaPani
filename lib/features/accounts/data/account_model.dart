// lib/features/accounts/data/account_model.dart
import 'package:flutter/material.dart';

class Account {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final double balance;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.balance,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    double? balance,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color.toARGB32(),
        'balance': balance,
        'created_at': createdAt.toIso8601String(),
      };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        color: Color(map['color']),
        balance: map['balance'],
        createdAt: DateTime.parse(map['created_at']),
      );
}
