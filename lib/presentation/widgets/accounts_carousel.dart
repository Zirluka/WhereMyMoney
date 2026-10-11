import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/account.dart';

class AccountsCarousel extends StatelessWidget {
  final List<Account> accounts;
  final Account? selectedAccount;
  final ValueChanged<Account?> onAccountSelected;
  final VoidCallback onAddAccountPressed;

  const AccountsCarousel({
    super.key,
    required this.accounts,
    required this.selectedAccount,
    required this.onAccountSelected,
    required this.onAddAccountPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            GestureDetector(
              onTap: onAddAccountPressed,
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 18, color: AppColors.primaryLight),
                  SizedBox(width: 4),
                  Text(
                    'Новый счет',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              // Первая карточка: "Все счета"
              if (index == 0) {
                final isSelected = selectedAccount == null;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAccountSelected(null);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 130,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.darkBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.all_inclusive_rounded,
                            size: 16,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        Text(
                          'Все счета',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.darkTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final acc = accounts[index - 1];
              final isSelected = selectedAccount?.id == acc.id;
              final color = Color(acc.colorHex);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAccountSelected(acc);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.18)
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? color : AppColors.darkBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Icon(
                              IconHelper.getIcon(acc.iconName),
                              size: 15,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              acc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(acc.balance),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isSelected ? Colors.white : AppColors.darkTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
