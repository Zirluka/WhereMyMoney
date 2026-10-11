import 'package:flutter/material.dart';

/// Дизайн-токены WhereMyMoney (согласно принципам Taste Skill: Anti-Slop & Premium Fintech)
class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Financial Semantics (High Contrast)
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeLight = Color(0xFF34D399);
  static const Color incomeBg = Color(0x1A10B981);

  static const Color expense = Color(0xFFF43F5E); // Coral Rose (Мягче и премиальнее ядовито-красного)
  static const Color expenseLight = Color(0xFFFB7185);
  static const Color expenseBg = Color(0x1AF43F5E);

  static const Color transfer = Color(0xFF38BDF8); // Sky Blue
  static const Color transferBg = Color(0x1A38BDF8);

  static const Color warning = Color(0xFFF59E0B); // Amber

  // Obsidian Dark Theme (Глубокий космос вместо плоского серого)
  static const Color darkBg = Color(0xFF0A0E1A); // Deep Obsidian
  static const Color darkSurface = Color(0xFF131B2E); // Navy Slate
  static const Color darkCard = Color(0xFF182238); // Card Surface
  static const Color darkCardElevated = Color(0xFF1F2C47); // Hover/Elevated Card
  static const Color darkBorder = Color(0xFF263553); // Subtle Hairline Border
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextMuted = Color(0xFF64748B); // Slate 500

  // Light Theme (Чистый бумажный стиль)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Категории: сочная, гармоничная палитра
  static const List<Color> categoryPalette = [
    Color(0xFFF43F5E), // Продукты (Coral)
    Color(0xFFFB923C), // Кафе и рестораны (Orange)
    Color(0xFFFBBF24), // Транспорт и такси (Amber)
    Color(0xFF10B981), // Зарплата / Доход (Emerald)
    Color(0xFF14B8A6), // Здоровье / Аптека (Teal)
    Color(0xFF38BDF8), // Покупки / Одежда (Sky)
    Color(0xFF6366F1), // Счета / ЖКХ / Связь (Indigo)
    Color(0xFFA855F7), // Развлечения / Хобби (Purple)
    Color(0xFFEC4899), // Красота / Спорт (Pink)
    Color(0xFF64748B), // Прочее (Slate)
  ];
}
