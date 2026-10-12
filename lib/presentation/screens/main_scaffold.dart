import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'accounts_screen.dart';
import 'add_transaction_sheet.dart';
import 'analytics_screen.dart';
import 'budgets_and_goals_screen.dart';
import 'dashboard_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    BudgetsAndGoalsScreen(),
    AccountsScreen(),
  ];

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          border: Border(
            top: BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Обзор',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded),
              label: 'Аналитика',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.savings_outlined),
              activeIcon: Icon(Icons.savings_rounded),
              label: 'Бюджеты',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card_rounded),
              label: 'Счета',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить операцию',
        onPressed: () => AddTransactionSheet.show(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
