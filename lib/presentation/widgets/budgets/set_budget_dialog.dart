import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/budget.dart';
import 'package:where_my_money/data/models/category.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';

class SetBudgetDialog extends StatefulWidget {
  final Budget? existingBudget;

  const SetBudgetDialog({super.key, this.existingBudget});

  static Future<bool?> show(BuildContext context, {Budget? budget}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => SetBudgetDialog(existingBudget: budget),
    );
  }

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  final _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FinanceProvider>();
    final categories = provider.expenseCategories;

    if (widget.existingBudget != null) {
      _amountController.text = widget.existingBudget!.amount
          .toStringAsFixed(2)
          .replaceAll('.00', '');
      _selectedCategory = categories.firstWhere(
        (c) => c.id == widget.existingBudget!.categoryId,
        orElse: () => categories.first,
      );
    } else if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _amountController.text =
          amount.toStringAsFixed(2).replaceAll('.00', '');
    });
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную сумму лимита'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите категорию расходов'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    final provider = context.read<FinanceProvider>();
    final success = await provider.setBudget(
      categoryId: _selectedCategory!.id,
      amount: amount,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final categories = provider.expenseCategories;
    final isEditing = widget.existingBudget != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Изменить лимит категории' : 'Новый лимит категории',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор категории
            const Text(
              'Категория расхода:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Category>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  items: categories.map((cat) {
                    final color = Color(cat.colorHex);
                    return DropdownMenuItem<Category>(
                      value: cat,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Icon(
                              IconHelper.getIcon(cat.iconName),
                              color: color,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isEditing
                      ? null // Не меняем категорию при редактировании существующего бюджета
                      : (cat) {
                          if (cat != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          }
                        },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Поле лимита
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: 'Месячный лимит',
                suffixText: '₽',
                hintText: '25 000',
              ),
            ),

            const SizedBox(height: 12),

            // Быстрые суммы
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [5000.0, 10000.0, 20000.0, 50000.0].map((amt) {
                return ActionChip(
                  label: Text(CurrencyFormatter.format(amt)),
                  backgroundColor: AppColors.darkCard,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => _setAmount(amt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () async {
              final success = await provider.deleteBudget(widget.existingBudget!.id);
              if (success && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Удалить'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Сохранить' : 'Установить'),
        ),
      ],
    );
  }
}
