import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/currency_formatter.dart';
import 'core/utils/date_formatter.dart';
import 'core/utils/icon_helper.dart';
import 'core/utils/receipt_qr_parser.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/screens/add_transaction_sheet.dart';
import 'presentation/screens/qr_scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhereMyMoneyApp());
}

class WhereMyMoneyApp extends StatelessWidget {
  const WhereMyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..loadInitialData(),
      child: MaterialApp(
        title: 'WhereMyMoney',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhereMyMoney'),
        actions: [
          IconButton(
            tooltip: 'Сканировать чек по QR',
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
            onPressed: () => _scanReceiptQr(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : provider.error != null
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Карточка баланса
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Общий баланс',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.format(provider.totalBalance),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkTextPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Месячные расходы и доходы
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.expense.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppColors.expense
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.arrow_downward_rounded,
                                                size: 14,
                                                color: AppColors.expense),
                                            SizedBox(width: 4),
                                            Text(
                                              'Расходы',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.expenseLight,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(
                                              provider.monthlyExpense),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.expense,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.income.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppColors.income
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.arrow_upward_rounded,
                                                size: 14,
                                                color: AppColors.income),
                                            SizedBox(width: 4),
                                            Text(
                                              'Доходы',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.incomeLight,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(
                                              provider.monthlyIncome),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.income,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Кнопки быстрых действий
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 20),
                                    label: const Text(
                                      'Добавить',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    onPressed: () =>
                                        AddTransactionSheet.show(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.income,
                                      side: const BorderSide(
                                          color: AppColors.income, width: 1.5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 20),
                                    label: const Text(
                                      'Чек по QR',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    onPressed: () => _scanReceiptQr(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Счета
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Мои счета',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            '${provider.accounts.length} счетов',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.accounts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final acc = provider.accounts[index];
                            final color = Color(acc.colorHex);
                            return Container(
                              width: 160,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            color.withValues(alpha: 0.2),
                                        child: Icon(
                                          IconHelper.getIcon(acc.iconName),
                                          size: 14,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          acc.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    CurrencyFormatter.format(acc.balance),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Список операций
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'История операций',
                            style: TextStyle(
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
                      const SizedBox(height: 12),

                      if (provider.recentTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 36),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 48,
                                  color: AppColors.darkTextMuted
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'Нет операций',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Добавьте первую операцию вручную или отсканируйте чек по QR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...provider.recentTransactions.map((tx) {
                          final isExpense = tx.isExpense;
                          final isIncome = tx.isIncome;
                          final color = isExpense
                              ? AppColors.expense
                              : isIncome
                                  ? AppColors.income
                                  : AppColors.transfer;

                          return Dismissible(
                            key: Key(tx.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_rounded,
                                  color: AppColors.expense),
                            ),
                            onDismissed: (_) {
                              HapticFeedback.mediumImpact();
                              provider.deleteTransaction(tx.id);
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      (tx.categoryColor != null
                                              ? Color(tx.categoryColor!)
                                              : color)
                                          .withValues(alpha: 0.2),
                                  child: Icon(
                                    IconHelper.getIcon(tx.categoryIcon ?? ''),
                                    color: tx.categoryColor != null
                                        ? Color(tx.categoryColor!)
                                        : color,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tx.categoryName ?? (tx.isTransfer ? 'Перевод' : 'Операция'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (tx.qrRawData != null) ...[
                                      const Icon(
                                        Icons.qr_code_rounded,
                                        size: 16,
                                        color: AppColors.income,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  '${DateFormatter.formatShort(tx.date)} • ${tx.accountName ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                trailing: Text(
                                  CurrencyFormatter.format(tx.amount,
                                      showSign: true),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
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
