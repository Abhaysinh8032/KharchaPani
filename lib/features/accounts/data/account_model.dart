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
    required this.id, required this.name, required this.icon,
    required this.color, required this.balance, required this.createdAt,
  });

  Account copyWith({String? name, String? icon, Color? color, double? balance}) =>
      Account(
        id: id, createdAt: createdAt,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        balance: balance ?? this.balance,
      );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'icon': icon,
    'color': color.toARGB32(), 'balance': balance,
    'created_at': createdAt.toIso8601String(),
  };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'], name: m['name'], icon: m['icon'],
    color: Color(m['color'] as int),
    balance: (m['balance'] as num).toDouble(),
    createdAt: DateTime.parse(m['created_at']),
  );
}
