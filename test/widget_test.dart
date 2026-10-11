import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_theme.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'package:where_my_money/presentation/screens/main_scaffold.dart';

void main() {
  testWidgets('MainScaffold renders navigation items and dashboard', (WidgetTester tester) async {
    final provider = FinanceProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<FinanceProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainScaffold(),
        ),
      ),
    );

    await tester.pump();

    // Проверяем наличие элементов нижней навигации
    expect(find.text('Обзор'), findsOneWidget);
    expect(find.text('Аналитика'), findsOneWidget);
    expect(find.text('Счета'), findsOneWidget);

    // Проверяем наличие плавающей кнопки добавления
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
