import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import '../providers/finance_provider.dart';
import '../widgets/accounts/account_detail_sheet.dart';
import '../widgets/accounts/account_edit_dialog.dart';
import '../widgets/accounts/transfer_sheet.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Счета и кошельки'),
        actions: [
          IconButton(
            tooltip: 'Перевод между счетами',
            icon: const Icon(Icons.swap_horiz_rounded, size: 26),
            onPressed: () {
              HapticFeedback.selectionClick();
              TransferSheet.show(context);
            },
          ),
          IconButton(
            tooltip: 'Добавить счет',
            icon: const Icon(Icons.add_rounded, size: 26),
            onPressed: () {
              HapticFeedback.selectionClick();
              AccountEditDialog.show(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. КАРТОЧКА СОВОКУПНЫХ АКТИВОВ
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkCard,
                    AppColors.darkCard.withValues(alpha: 0.8),
                    AppColors.primary.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.darkBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Совокупные активы',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.darkTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Text(
                          '${provider.accounts.length} ${_getAccountsWord(provider.accounts.length)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(provider.totalBalance),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.income,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Быстрые кнопки в карточке
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text(
                            'Перевести',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            TransferSheet.show(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: AppColors.darkBorder),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Новый счет',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            AccountEditDialog.show(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // 2. ЗАГОЛОВОК СПИСКА СЧЕТОВ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ваши счета',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Нажмите для деталей',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. КАРТОЧКИ СЧЕТОВ (Apple Wallet style)
            ...provider.accounts.map((account) {
              final color = Color(account.colorHex);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      AccountDetailSheet.show(context, account);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.12),
                            AppColors.darkCard,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: color.withValues(alpha: 0.22),
                            child: Icon(
                              IconHelper.getIcon(account.iconName),
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      account.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkSurface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.darkBorder),
                                      ),
                                      child: Text(
                                        account.currency,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(account.balance),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: AppColors.darkTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.darkTextMuted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Кнопка быстрого добавления внизу списка
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: AppColors.darkBorder.withValues(alpha: 0.8),
                  style: BorderStyle.solid,
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primaryLight),
              label: const Text(
                'Добавить еще один кошелек',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                AccountEditDialog.show(context);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getAccountsWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'счетов';
    if (mod10 == 1) return 'счет';
    if (mod10 >= 2 && mod10 <= 4) return 'счета';
    return 'счетов';
  }
}
