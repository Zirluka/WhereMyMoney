import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/date_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/transaction_item.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';

class CategoryTransactionsSheet extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int categoryColorHex;
  final DateTime startDate;
  final DateTime endDate;

  const CategoryTransactionsSheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.startDate,
    required this.endDate,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryId,
    required String categoryName,
    required String categoryIcon,
    required int categoryColorHex,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryTransactionsSheet(
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColorHex: categoryColorHex,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  State<CategoryTransactionsSheet> createState() => _CategoryTransactionsSheetState();
}

class _CategoryTransactionsSheetState extends State<CategoryTransactionsSheet> {
  List<TransactionItem> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryTransactions();
  }

  Future<void> _loadCategoryTransactions() async {
    final provider = context.read<FinanceProvider>();
    // Фильтруем транзакции по категории и периоду
    final allTransactions = provider.recentTransactions;
    // Или можно запросить через репозиторий через прямой вызов если нужно
    // Поскольку у нас есть recentTransactions в провайдере или мы можем отфильтровать:
    final filtered = allTransactions.where((t) {
      final isCat = t.categoryId == widget.categoryId;
      final inRange = t.date.isAfter(widget.startDate.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(widget.endDate.add(const Duration(seconds: 1)));
      return isCat && inRange;
    }).toList();

    if (mounted) {
      setState(() {
        _transactions = filtered;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.categoryColorHex);
    double totalAmount = 0;
    for (final t in _transactions) {
      totalAmount += t.amount;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Заголовок категории
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    IconHelper.getIcon(widget.categoryIcon),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Всего: ${CurrencyFormatter.format(totalAmount)} • ${_transactions.length} операций',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.darkBorder),

          // Список транзакций
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Нет операций по этой категории',
                          style: TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _transactions[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.note?.isNotEmpty == true
                                            ? item.note!
                                            : widget.categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            DateFormatter.formatShort(item.date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.darkTextMuted,
                                            ),
                                          ),
                                          if (item.qrRawData != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'ЧЕК ФНС',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primaryLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.amount),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: item.isIncome
                                        ? AppColors.income
                                        : AppColors.darkTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
