import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> _icons = {
    'shopping_cart': Icons.shopping_cart_rounded,
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'work': Icons.work_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'school': Icons.school_rounded,
    'flight': Icons.flight_rounded,
    'home': Icons.home_rounded,
    'credit_card': Icons.credit_card_rounded,
    'payments': Icons.payments_rounded,
    'account_balance': Icons.account_balance_rounded,
    'savings': Icons.savings_rounded,
    'attach_money': Icons.attach_money_rounded,
    'trending_up': Icons.trending_up_rounded,
    'fastfood': Icons.fastfood_rounded,
    'category': Icons.category_rounded,
    'wallet': Icons.wallet_rounded,
    'currency_bitcoin': Icons.currency_bitcoin_rounded,
    'euro': Icons.euro_rounded,
    'security': Icons.security_rounded,
  };

  static IconData getIcon(String name) {
    return _icons[name] ?? Icons.category_rounded;
  }

  static String getIconName(IconData icon) {
    for (final entry in _icons.entries) {
      if (entry.value == icon) return entry.key;
    }
    return 'category';
  }

  static List<String> get availableIconNames => _icons.keys.toList();
}
