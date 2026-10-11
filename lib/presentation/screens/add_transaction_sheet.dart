import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/receipt_qr_parser.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../providers/finance_provider.dart';
import 'qr_scanner_screen.dart';

class AddTransactionSheet extends StatefulWidget {
  final ReceiptData? initialReceiptData;

  const AddTransactionSheet({super.key, this.initialReceiptData});

  static Future<void> show(BuildContext context, {ReceiptData? receiptData}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(initialReceiptData: receiptData),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _type = 'expense'; // 'expense', 'income', 'transfer'
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _targetAccount; // Для перевода
  DateTime _date = DateTime.now();
  String? _qrRawData;
  bool _isFiscalReceipt = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FinanceProvider>();
    _selectedAccount = provider.selectedAccount ??
        (provider.accounts.isNotEmpty ? provider.accounts.first : null);
    if (provider.accounts.length > 1) {
      _targetAccount = provider.accounts[1];
    }

    if (_type == 'expense' && provider.expenseCategories.isNotEmpty) {
      _selectedCategory = provider.expenseCategories.first;
    }

    // Если передан результат сканирования чека
    if (widget.initialReceiptData != null) {
      _applyReceiptData(widget.initialReceiptData!);
    }
  }

  void _applyReceiptData(ReceiptData data) {
    _amountController.text = data.amount.toStringAsFixed(2).replaceAll('.00', '');
    _date = data.date;
    _qrRawData = data.rawData;
    _isFiscalReceipt = data.isFiscal;
    _type = 'expense';

    final provider = context.read<FinanceProvider>();
    // По умолчанию для чека выбираем «Продукты», если доступно
    final groceries = provider.expenseCategories.firstWhere(
      (c) => c.name.toLowerCase().contains('продукт'),
      orElse: () => provider.expenseCategories.first,
    );
    _selectedCategory = groceries;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _evaluateAmount() {
    final text = _amountController.text.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (text.isEmpty) return null;

    // Поддержка простого сложения выражений вида 250+150
    if (text.contains('+')) {
      final parts = text.split('+');
      double sum = 0;
      for (final part in parts) {
        final val = double.tryParse(part);
        if (val == null) return null;
        sum += val;
      }
      return sum;
    }

    return double.tryParse(text);
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<ReceiptData>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _applyReceiptData(result);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    final amount = _evaluateAmount();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную сумму'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите счет списания'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final provider = context.read<FinanceProvider>();
    final categoryId = _type == 'transfer'
        ? (_selectedCategory?.id ?? provider.categories.first.id)
        : (_selectedCategory?.id ?? provider.categories.first.id);

    HapticFeedback.lightImpact();

    final success = await provider.addTransaction(
      accountId: _selectedAccount!.id,
      categoryId: categoryId,
      amount: amount,
      type: _type,
      date: _date,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      qrRawData: _qrRawData,
      targetAccountId: _type == 'transfer' ? _targetAccount?.id : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final categories = _type == 'income'
        ? provider.incomeCategories
        : provider.expenseCategories;

    final themeColor = _type == 'expense'
        ? AppColors.expense
        : _type == 'income'
            ? AppColors.income
            : AppColors.transfer;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Хэндл для свайпа закрытия
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkTextMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Верхний ряд: Переключатель типа и кнопка QR-сканера
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        _buildTypeSegment('Расход', 'expense', AppColors.expense),
                        _buildTypeSegment('Доход', 'income', AppColors.income),
                        _buildTypeSegment('Перевод', 'transfer', AppColors.transfer),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Кнопка QR чека
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openQrScanner,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isFiscalReceipt
                            ? AppColors.income.withValues(alpha: 0.15)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isFiscalReceipt
                              ? AppColors.income
                              : AppColors.darkBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: _isFiscalReceipt
                            ? AppColors.income
                            : AppColors.darkTextPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isFiscalReceipt) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: AppColors.income),
                  const SizedBox(width: 6),
                  Text(
                    'Данные чека ФНС распознаны',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.incomeLight,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Поле ввода суммы (Крупная цифра)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      autofocus: widget.initialReceiptData == null,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                        letterSpacing: -1,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text(
                    '₽',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Выбор счетов
            if (_type == 'transfer') ...[
              const Text(
                'Счет списания и счет зачисления:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Account>(
                      initialValue: _selectedAccount,
                      dropdownColor: AppColors.darkCard,
                      decoration: const InputDecoration(labelText: 'Откуда'),
                      items: provider.accounts.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccount = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.darkTextMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Account>(
                      initialValue: _targetAccount,
                      dropdownColor: AppColors.darkCard,
                      decoration: const InputDecoration(labelText: 'Куда'),
                      items: provider.accounts
                          .where((a) => a.id != _selectedAccount?.id)
                          .map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _targetAccount = val),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Горизонтальный выбор счета
              Row(
                children: [
                  const Text(
                    'Счет: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.accounts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final acc = provider.accounts[index];
                          final isSelected = acc.id == _selectedAccount?.id;
                          return ChoiceChip(
                            label: Text(acc.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedAccount = acc);
                              }
                            },
                            avatar: Icon(
                              IconHelper.getIcon(acc.iconName),
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : Color(acc.colorHex),
                            ),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.darkCard,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkBorder,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkTextPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Сетка категорий (если не перевод)
            if (_type != 'transfer') ...[
              const Text(
                'Категория:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = cat.id == _selectedCategory?.id;
                  final catColor = Color(cat.colorHex);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.25)
                              : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? catColor : AppColors.darkBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconHelper.getIcon(cat.iconName),
                              size: 16,
                              color: catColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.darkTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Дата и Заметка
            Row(
              children: [
                // Кнопка выбора даты
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.darkTextSecondary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.formatDayHeader(_date),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Заметка
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Заметка (опционально)',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  'Сохранить операцию',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegment(String title, String typeValue, Color activeColor) {
    final isSelected = _type == typeValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _type = typeValue;
            final provider = context.read<FinanceProvider>();
            if (typeValue == 'income' && provider.incomeCategories.isNotEmpty) {
              _selectedCategory = provider.incomeCategories.first;
            } else if (typeValue == 'expense' && provider.expenseCategories.isNotEmpty) {
              _selectedCategory = provider.expenseCategories.first;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : AppColors.darkTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
