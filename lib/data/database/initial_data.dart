import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/category.dart';

class InitialData {
  static const _uuid = Uuid();

  static List<Account> getDefaultAccounts() {
    final now = DateTime.now();
    return [
      Account(
        id: _uuid.v4(),
        name: 'Основная карта',
        balance: 0.0,
        currency: 'RUB',
        colorHex: 0xFF6366F1, // Indigo
        iconName: 'credit_card',
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: _uuid.v4(),
        name: 'Наличные',
        balance: 0.0,
        currency: 'RUB',
        colorHex: 0xFF10B981, // Emerald
        iconName: 'payments',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<Category> getDefaultCategories() {
    final now = DateTime.now();
    return [
      // Расходные категории
      Category(
        id: _uuid.v4(),
        name: 'Продукты',
        type: 'expense',
        iconName: 'shopping_cart',
        colorHex: 0xFFF43F5E,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Кафе и рестораны',
        type: 'expense',
        iconName: 'restaurant',
        colorHex: 0xFFFB923C,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Транспорт',
        type: 'expense',
        iconName: 'directions_car',
        colorHex: 0xFFFBBF24,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Покупки',
        type: 'expense',
        iconName: 'shopping_bag',
        colorHex: 0xFF38BDF8,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Здоровье и аптека',
        type: 'expense',
        iconName: 'local_hospital',
        colorHex: 0xFF14B8A6,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'ЖКХ и связь',
        type: 'expense',
        iconName: 'receipt_long',
        colorHex: 0xFF6366F1,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Развлечения',
        type: 'expense',
        iconName: 'sports_esports',
        colorHex: 0xFFA855F7,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Спорт и фитнес',
        type: 'expense',
        iconName: 'fitness_center',
        colorHex: 0xFFEC4899,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Дом и ремонт',
        type: 'expense',
        iconName: 'home',
        colorHex: 0xFF0284C7,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Прочее',
        type: 'expense',
        iconName: 'category',
        colorHex: 0xFF64748B,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Доходные категории
      Category(
        id: _uuid.v4(),
        name: 'Зарплата',
        type: 'income',
        iconName: 'work',
        colorHex: 0xFF10B981,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Подработка',
        type: 'income',
        iconName: 'trending_up',
        colorHex: 0xFF34D399,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Инвестиции',
        type: 'income',
        iconName: 'savings',
        colorHex: 0xFF38BDF8,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: _uuid.v4(),
        name: 'Подарки',
        type: 'income',
        iconName: 'attach_money',
        colorHex: 0xFFFBBF24,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
