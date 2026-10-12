import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/receipt_qr_parser.dart';
import '../providers/finance_provider.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/balance_card.dart';
import '../widgets/accounts_carousel.dart';
import '../widgets/grouped_transactions_list.dart';
import 'add_transaction_sheet.dart';
import 'backup_and_settings_screen.dart';
import 'qr_scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _scanReceiptQr(BuildContext context) async {
    final receiptData = await Navigator.of(context).push<ReceiptData>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (receiptData != null && context.mounted) {
      AddTransactionSheet.show(context, receiptData: receiptData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.expense),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.expense),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => provider.loadInitialData(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhereMyMoney'),
        actions: [
          IconButton(
            tooltip: 'Сканировать чек',
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
            onPressed: () => _scanReceiptQr(context),
          ),
          IconButton(
            tooltip: 'Данные и бэкап',
            icon: const Icon(Icons.settings_outlined, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupAndSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Главная карточка баланса и быстрых действий
            BalanceCard(
              totalBalance: provider.totalBalance,
              monthlyExpense: provider.monthlyExpense,
              monthlyIncome: provider.monthlyIncome,
              onAddPressed: () => AddTransactionSheet.show(context),
              onScanQrPressed: () => _scanReceiptQr(context),
            ),
            const SizedBox(height: 24),

            // Карусель счетов
            AccountsCarousel(
              accounts: provider.accounts,
              selectedAccount: provider.selectedAccount,
              onAccountSelected: (acc) => provider.selectAccount(acc),
              onAddAccountPressed: () => AddAccountDialog.show(context),
            ),
            const SizedBox(height: 24),

            // Заголовок списка транзакций
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.selectedAccount != null
                      ? 'Операции: ${provider.selectedAccount!.name}'
                      : 'Все операции',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (provider.recentTransactions.isNotEmpty)
                  Text(
                    '${provider.recentTransactions.length} записей',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Группированный по дням список операций
            GroupedTransactionsList(
              transactions: provider.recentTransactions,
              onDeleteTransaction: (id) => provider.deleteTransaction(id),
            ),
          ],
        ),
      ),
    );
  }
}
