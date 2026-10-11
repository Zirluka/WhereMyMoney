import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );

  static final NumberFormat _fractionalFormatter = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  /// Форматирует сумму:
  /// format(1500) -> "1 500 ₽"
  /// format(1500.50) -> "1 500,50 ₽"
  /// format(1500, showSign: true) -> "+1 500 ₽"
  /// format(-1500, showSign: true) -> "-1 500 ₽"
  static String format(double amount, {bool showSign = false, String symbol = '₽'}) {
    final hasFractions = (amount.abs() % 1) != 0;
    final formatter = hasFractions ? _fractionalFormatter : _formatter;
    final formatted = formatter.format(amount.abs());

    if (showSign) {
      if (amount > 0) return '+$formatted';
      if (amount < 0) return '-$formatted';
    }
    return formatted;
  }
}
