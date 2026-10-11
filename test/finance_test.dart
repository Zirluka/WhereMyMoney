import 'package:flutter_test/flutter_test.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/date_formatter.dart';
import 'package:where_my_money/core/utils/receipt_qr_parser.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/data/models/category.dart';
import 'package:where_my_money/data/models/transaction_item.dart';

void main() {
  group('Models Serialization Tests', () {
    test('Account toMap and fromMap serialization', () {
      final now = DateTime.now();
      final account = Account(
        id: 'acc-1',
        name: 'Т-Банк',
        balance: 15400.50,
        currency: 'RUB',
        colorHex: 0xFF6366F1,
        iconName: 'credit_card',
        createdAt: now,
        updatedAt: now,
      );

      final map = account.toMap();
      final restored = Account.fromMap(map);

      expect(restored.id, account.id);
      expect(restored.name, account.name);
      expect(restored.balance, account.balance);
      expect(restored.currency, 'RUB');
      expect(restored.colorHex, account.colorHex);
    });

    test('Category toMap and fromMap serialization', () {
      final now = DateTime.now();
      final category = Category(
        id: 'cat-1',
        name: 'Продукты',
        type: 'expense',
        iconName: 'shopping_cart',
        colorHex: 0xFFF43F5E,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = category.toMap();
      final restored = Category.fromMap(map);

      expect(restored.id, category.id);
      expect(restored.name, category.name);
      expect(restored.isExpense, isTrue);
      expect(restored.isDefault, isTrue);
    });

    test('TransactionItem toMap and fromMap serialization', () {
      final now = DateTime.now();
      final tx = TransactionItem(
        id: 'tx-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        amount: 850.0,
        type: 'expense',
        date: now,
        note: 'Обед',
        createdAt: now,
        updatedAt: now,
      );

      final map = tx.toMap();
      final restored = TransactionItem.fromMap(map);

      expect(restored.id, tx.id);
      expect(restored.amount, 850.0);
      expect(restored.isExpense, isTrue);
      expect(restored.note, 'Обед');
    });
  });

  group('Formatters Tests', () {
    test('CurrencyFormatter formats rubles properly', () {
      final formatted = CurrencyFormatter.format(1500);
      expect(formatted.contains('1'), isTrue);
      expect(formatted.contains('500'), isTrue);
      expect(formatted.contains('₽'), isTrue);

      final signedPositive = CurrencyFormatter.format(1500, showSign: true);
      expect(signedPositive.startsWith('+'), isTrue);

      final signedNegative = CurrencyFormatter.format(-1500, showSign: true);
      expect(signedNegative.startsWith('-'), isTrue);
    });

    test('DateFormatter headers formatting', () {
      final today = DateTime.now();
      final header = DateFormatter.formatDayHeader(today);
      expect(header.startsWith('Сегодня'), isTrue);
    });
  });

  group('ReceiptQrParser Tests', () {
    test('Parses Russian FNS fiscal QR string correctly', () {
      const qr = 't=20261012T143000&s=1240.50&fn=9960440300123456&i=15243&fp=3857291023&n=1';
      final parsed = ReceiptQrParser.parse(qr);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1240.50);
      expect(parsed.isFiscal, isTrue);
      expect(parsed.fn, '9960440300123456');
      expect(parsed.fd, '15243');
      expect(parsed.fp, '3857291023');
      expect(parsed.date.year, 2026);
      expect(parsed.date.month, 10);
      expect(parsed.date.day, 12);
      expect(parsed.date.hour, 14);
      expect(parsed.date.minute, 30);
    });

    test('Parses QR with comma as decimal separator', () {
      const qr = 't=20261012T1000&s=350,90&fn=111&i=222&fp=333';
      final parsed = ReceiptQrParser.parse(qr);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 350.90);
    });

    test('Returns null on empty or non-receipt string', () {
      expect(ReceiptQrParser.parse(''), isNull);
      expect(ReceiptQrParser.parse('hello world'), isNull);
    });
  });
}
