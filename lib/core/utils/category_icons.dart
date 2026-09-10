// lib/core/utils/category_icons.dart
import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData get(String icon) {
    const map = {
      'baby': Icons.child_care,
      'beauty': Icons.spa,
      'bills': Icons.receipt_long,
      'car': Icons.directions_car,
      'clothing': Icons.checkroom,
      'data': Icons.data_usage,
      'education': Icons.school,
      'electronics': Icons.devices,
      'entertainment': Icons.movie,
      'family': Icons.home,
      'food': Icons.restaurant,
      'friends': Icons.people,
      'health': Icons.favorite,
      'home': Icons.house,
      'insurance': Icons.verified_user,
      'knowledge': Icons.lightbulb,
      'selfcare': Icons.self_improvement,
      'shopping': Icons.shopping_cart,
      'social': Icons.groups,
      'sport': Icons.sports_tennis,
      'tax': Icons.account_balance,
      'telephone': Icons.phone_android,
      'transportation': Icons.directions_bus,
      // Income
      'awards': Icons.emoji_events,
      'coupons': Icons.local_offer,
      'grants': Icons.card_giftcard,
      'lottery': Icons.confirmation_number,
      'refunds': Icons.replay,
      'rental': Icons.apartment,
      'salary': Icons.account_balance_wallet,
      'sale': Icons.sell,
      // Accounts
      'card': Icons.credit_card,
      'cash': Icons.payments,
      'savings': Icons.savings,
      'bank': Icons.account_balance,
    };
    return map[icon] ?? Icons.category;
  }

  static IconData accountIcon(String icon) {
    const map = {
      'card': Icons.credit_card,
      'cash': Icons.payments,
      'savings': Icons.savings,
      'bank': Icons.account_balance,
      'wallet': Icons.account_balance_wallet,
    };
    return map[icon] ?? Icons.account_balance_wallet;
  }
}
