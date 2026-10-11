import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class BalanceCard extends StatefulWidget {
  final double totalBalance;
  final double monthlyExpense;
  final double monthlyIncome;
  final VoidCallback onAddPressed;
  final VoidCallback onScanQrPressed;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyExpense,
    required this.monthlyIncome,
    required this.onAddPressed,
    required this.onScanQrPressed,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isBalanceHidden = false;

  void _toggleBalanceVisibility() {
    HapticFeedback.selectionClick();
    setState(() {
      _isBalanceHidden = !_isBalanceHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и иконка скрытия баланса (Privacy Toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Общий баланс',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _isBalanceHidden ? 'Показать баланс' : 'Скрыть баланс',
                icon: Icon(
                  _isBalanceHidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: AppColors.darkTextSecondary,
                ),
                onPressed: _toggleBalanceVisibility,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Сумма общего баланса
          Text(
            _isBalanceHidden
                ? '•••••• ₽'
                : CurrencyFormatter.format(widget.totalBalance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.darkTextPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),

          // Доходы и расходы за текущий месяц
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded,
                              size: 14, color: AppColors.expense),
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
                        _isBalanceHidden
                            ? '•••• ₽'
                            : CurrencyFormatter.format(widget.monthlyExpense),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.income.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 14, color: AppColors.income),
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
                        _isBalanceHidden
                            ? '•••• ₽'
                            : CurrencyFormatter.format(widget.monthlyIncome),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Добавить',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: widget.onAddPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.income,
                    side: const BorderSide(color: AppColors.income, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text(
                    'Чек по QR',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: widget.onScanQrPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
