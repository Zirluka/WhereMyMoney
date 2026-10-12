import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class PinNumpad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometrics;

  const PinNumpad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.onBiometricPressed,
    this.showBiometrics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildDigitButton(digit),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Левая кнопка: биометрия или пусто
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: showBiometrics && onBiometricPressed != null
              ? _buildActionButton(
                  icon: Icons.fingerprint_rounded,
                  iconColor: AppColors.income,
                  tooltip: 'Биометрия',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onBiometricPressed!();
                  },
                )
              : const SizedBox(width: 72, height: 72),
        ),

        // Цифра 0
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildDigitButton('0'),
        ),

        // Правая кнопка: Backspace (стереть)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildActionButton(
            icon: Icons.backspace_outlined,
            iconColor: AppColors.darkTextSecondary,
            tooltip: 'Стереть',
            onTap: () {
              HapticFeedback.lightImpact();
              onBackspacePressed();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDigitButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onDigitPressed(digit);
        },
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primary.withValues(alpha: 0.25),
        highlightColor: AppColors.primary.withValues(alpha: 0.15),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkCard,
            border: Border.all(
              color: AppColors.darkBorder.withValues(alpha: 0.8),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: iconColor.withValues(alpha: 0.2),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Icon(icon, size: 28, color: iconColor),
        ),
      ),
    );
  }
}
