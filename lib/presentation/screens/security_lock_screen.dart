import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/security_provider.dart';
import '../widgets/security/pin_dots_indicator.dart';
import '../widgets/security/pin_numpad.dart';

class SecurityLockScreen extends StatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
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
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final provider = context.read<SecurityProvider>();
    final success = await provider.unlockWithPin(_enteredPin);

    if (!mounted) return;

    if (!success) {
      HapticFeedback.heavyImpact();
      await _shakeController.forward(from: 0.0);
      if (mounted) {
        setState(() {
          _enteredPin = '';
        });
      }
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SecurityProvider>();

    return PopScope(
      canPop: false, // Запрет закрытия экрана разблокировки кнопкой "Назад"
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Шапка с брендингом и иконкой замка
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WhereMyMoney',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Введите PIN-код для доступа',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Индикатор заполненных точек и ошибка
                  PinDotsIndicator(
                    pinLength: 4,
                    enteredLength: _enteredPin.length,
                    shakeController: _shakeController,
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: provider.errorMessage != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      provider.errorMessage ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.expense,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Цифровая клавиатура Numpad
                  PinNumpad(
                    onDigitPressed: _onDigitPressed,
                    onBackspacePressed: _onBackspacePressed,
                    showBiometrics: provider.isBiometricsEnabled && provider.isBiometricsAvailable,
                    onBiometricPressed: () => provider.unlockWithBiometrics(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
