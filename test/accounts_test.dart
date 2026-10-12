import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_theme.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'package:where_my_money/presentation/screens/accounts_screen.dart';
import 'package:where_my_money/presentation/widgets/accounts/account_edit_dialog.dart';
import 'package:where_my_money/presentation/widgets/accounts/transfer_sheet.dart';

void main() {
  group('Accounts & Transfers Widget Tests', () {
    testWidgets('AccountsScreen renders total balance and actions', (tester) async {
      final provider = FinanceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<FinanceProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AccountsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Счета и кошельки'), findsOneWidget);
      expect(find.text('Совокупные активы'), findsOneWidget);
      expect(find.text('Перевести'), findsWidgets);
      expect(find.text('Новый счет'), findsOneWidget);
    });

    testWidgets('AccountEditDialog renders name, currency, and create button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AccountEditDialog(),
          ),
        ),
      );

      expect(find.text('Новый счет или кошелек'), findsOneWidget);
      expect(find.text('Название счета'), findsOneWidget);
      expect(find.text('Баланс'), findsOneWidget);
      expect(find.text('Валюта'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);
    });

    testWidgets('AccountEditDialog renders edit mode title and fields', (tester) async {
      final acc = Account(
        id: 'acc-1',
        name: 'Криптокошелек',
        balance: 1500.0,
        currency: 'USDT',
        colorHex: 0xFF10B981,
        iconName: 'currency_bitcoin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AccountEditDialog(account: acc),
          ),
        ),
      );

      expect(find.text('Редактировать счет'), findsOneWidget);
      expect(find.text('Криптокошелек'), findsOneWidget);
      expect(find.text('Сохранить'), findsOneWidget);
    });

    testWidgets('TransferSheet renders swap button and quick amounts', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = FinanceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<FinanceProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: TransferSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Перевод между счетами'), findsOneWidget);
      expect(find.text('Откуда списать'), findsOneWidget);
      expect(find.text('Куда зачислить'), findsOneWidget);
      expect(find.text('Сумма перевода'), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
      expect(find.text('Выполнить перевод', skipOffstage: false), findsOneWidget);
    });
  });
}
