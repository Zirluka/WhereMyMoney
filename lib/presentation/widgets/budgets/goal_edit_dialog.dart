import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/savings_goal.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';

class GoalEditDialog extends StatefulWidget {
  final SavingsGoal? goal;

  const GoalEditDialog({super.key, this.goal});

  static Future<bool?> show(BuildContext context, {SavingsGoal? goal}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => GoalEditDialog(goal: goal),
    );
  }

  @override
  State<GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<GoalEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentAmountController;

  DateTime? _targetDate;
  late String _selectedIcon;
  late int _selectedColor;

  final List<String> _goalIcons = [
    'savings',
    'flight',
    'home',
    'directions_car',
    'sports_esports',
    'school',
    'shopping_bag',
    'wallet',
    'security',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(2).replaceAll('.00', '') : '',
    );
    _currentAmountController = TextEditingController(
      text: g != null ? g.currentAmount.toStringAsFixed(2).replaceAll('.00', '') : '0',
    );
    _targetDate = g?.targetDate;
    _selectedIcon = g?.iconName ?? 'savings';
    _selectedColor = g?.colorHex ?? AppColors.categoryPalette[1].toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название цели'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final targetText = _targetAmountController.text.trim().replaceAll(',', '.');
    final targetAmount = double.tryParse(targetText);
    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную целевую сумму'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final currentText = _currentAmountController.text.trim().replaceAll(',', '.');
    final currentAmount = double.tryParse(currentText) ?? 0.0;

    HapticFeedback.lightImpact();
    final provider = context.read<FinanceProvider>();

    bool success;
    if (widget.goal != null) {
      final updated = widget.goal!.copyWith(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );
      success = await provider.updateSavingsGoal(updated);
    } else {
      success = await provider.addSavingsGoal(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Редактировать цель' : 'Новая финансовая цель',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              decoration: const InputDecoration(
                labelText: 'Название цели',
                hintText: 'Отпуск, Автомобиль, Подушка безопасности',
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Цель (₽)',
                      hintText: '100 000',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _currentAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Накоплено (₽)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Выбор дедлайна
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.darkTextSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _targetDate != null
                              ? 'Дедлайн: ${DateFormat('dd.MM.yyyy').format(_targetDate!)}'
                              : 'Указать желаемую дату',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _targetDate != null
                                ? AppColors.darkTextPrimary
                                : AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: const Icon(Icons.close_rounded, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Иконка:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalIcons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = iconName);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.darkBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      IconHelper.getIcon(iconName),
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.darkTextSecondary,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            const Text(
              'Цвет:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.categoryPalette.map((color) {
                final colorValue = color.toARGB32();
                final isSelected = _selectedColor == colorValue;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = colorValue);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Сохранить' : 'Создать цель'),
        ),
      ],
    );
  }
}
