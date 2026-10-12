import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/security_provider.dart';
import 'pin_dots_indicator.dart';
import 'pin_numpad.dart';

class SetPinDialog extends StatefulWidget {
  const SetPinDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const SetPinDialog(),
    );
  }

  @override
  State<SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<SetPinDialog>
    with SingleTickerProviderStateMixin {
  int _step = 1; // 1 = Придумайте PIN, 2 = Повторите PIN
  String _firstPin = '';
  String _enteredPin = '';
  String? _errorMessage;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _processStep();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _processStep() async {
    if (_step == 1) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _step = 2;
      });
      HapticFeedback.selectionClick();
    } else {
      if (_enteredPin == _firstPin) {
        // Успешная установка
        final provider = context.read<SecurityProvider>();
        await provider.setPin(_enteredPin);

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      } else {
        // Несовпадение
        HapticFeedback.heavyImpact();
        await _shakeController.forward(from: 0.0);
        if (mounted) {
          setState(() {
            _step = 1;
            _firstPin = '';
            _enteredPin = '';
            _errorMessage = 'PIN-коды не совпали. Попробуйте снова';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Полоска-ручка шторки
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkTextMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _step == 1 ? 'Придумайте PIN-код' : 'Повторите PIN-код',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _step == 1
                ? 'Введите 4 цифры для защиты доступа'
                : 'Повторите ввод для подтверждения',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Индикатор точек PIN
          PinDotsIndicator(
            pinLength: 4,
            enteredLength: _enteredPin.length,
            shakeController: _shakeController,
          ),
          const SizedBox(height: 12),

          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.expense,
              ),
            )
          else
            const SizedBox(height: 14),

          const SizedBox(height: 16),

          // Клавиатура ввода
          PinNumpad(
            onDigitPressed: _onDigitPressed,
            onBackspacePressed: _onBackspacePressed,
            showBiometrics: false,
          ),
        ],
      ),
    );
  }
}
