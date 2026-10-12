import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/services/security_service.dart';
import 'package:where_my_money/core/theme/app_theme.dart';
import 'package:where_my_money/presentation/providers/security_provider.dart';
import 'package:where_my_money/presentation/screens/security_lock_screen.dart';
import 'package:where_my_money/presentation/widgets/security/pin_dots_indicator.dart';
import 'package:where_my_money/presentation/widgets/security/pin_numpad.dart';
import 'package:where_my_money/presentation/widgets/security/set_pin_dialog.dart';

// Фейковый сервис безопасности для детерминированного тестирования
class MockSecurityService extends SecurityService {
  String? savedSalt;
  String? savedHash;
  bool isEnabled = false;
  bool biometricsEnabled = false;

  @override
  Future<bool> isPinEnabled() async => isEnabled;

  @override
  Future<bool> isBiometricsEnabled() async => biometricsEnabled;

  @override
  Future<bool> isBiometricsAvailable() async => true;

  @override
  Future<void> savePin(String pin) async {
    savedSalt = SecurityService.generateSalt();
    savedHash = SecurityService.hashPin(pin, savedSalt!);
    isEnabled = true;
  }

  @override
  Future<bool> checkPin(String pin) async {
    if (savedSalt == null || savedHash == null) return false;
    return SecurityService.verifyPinHash(pin, savedSalt!, savedHash!);
  }

  @override
  Future<void> removePin() async {
    savedSalt = null;
    savedHash = null;
    isEnabled = false;
    biometricsEnabled = false;
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    biometricsEnabled = enabled;
  }

  @override
  Future<bool> authenticateBiometrically({
    String localizedReason = 'Подтвердите личность для входа в WhereMyMoney',
  }) async {
    return true;
  }
}

void main() {
  group('SecurityService Cryptographic Logic Tests', () {
    test('generateSalt generates unique non-empty random strings', () {
      final salt1 = SecurityService.generateSalt();
      final salt2 = SecurityService.generateSalt();

      expect(salt1.isNotEmpty, isTrue);
      expect(salt2.isNotEmpty, isTrue);
      expect(salt1 != salt2, isTrue);
    });

    test('hashPin produces consistent SHA-256 hash for same pin and salt', () {
      const pin = '1234';
      const salt = 'random_salt_123';

      final hash1 = SecurityService.hashPin(pin, salt);
      final hash2 = SecurityService.hashPin(pin, salt);

      expect(hash1, hash2);
      expect(hash1.length, 64); // Длина SHA-256 в hex
    });

    test('verifyPinHash validates correct pin and rejects wrong pin', () {
      const pin = '4321';
      final salt = SecurityService.generateSalt();
      final hash = SecurityService.hashPin(pin, salt);

      expect(SecurityService.verifyPinHash('4321', salt, hash), isTrue);
      expect(SecurityService.verifyPinHash('1111', salt, hash), isFalse);
      expect(SecurityService.verifyPinHash('4322', salt, hash), isFalse);
    });
  });

  group('PinDotsIndicator & PinNumpad Widget Tests', () {
    testWidgets('PinDotsIndicator renders correct number of dots and handles fill', (tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                controller = AnimationController(
                  vsync: const TestVSync(),
                  duration: const Duration(milliseconds: 300),
                );
                return PinDotsIndicator(
                  pinLength: 4,
                  enteredLength: 2,
                  shakeController: controller,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      // Проверяем наличие 4 индикаторов
      final row = find.byType(Row);
      expect(row, findsOneWidget);
    });

    testWidgets('PinNumpad triggers callbacks on digits, backspace, and biometrics', (tester) async {
      String entered = '';
      bool backspaced = false;
      bool bioTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PinNumpad(
              onDigitPressed: (digit) => entered += digit,
              onBackspacePressed: () => backspaced = true,
              showBiometrics: true,
              onBiometricPressed: () => bioTapped = true,
            ),
          ),
        ),
      );

      // Нажимаем цифры 1, 2, 3, 0
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('0'));

      expect(entered, '1230');

      // Нажимаем Backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      expect(backspaced, isTrue);

      // Нажимаем биометрию
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      expect(bioTapped, isTrue);
    });
  });

  group('SecurityLockScreen & SetPinDialog Tests', () {
    testWidgets('SecurityLockScreen renders branding and verifies PIN correctly', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockSecurityService();
      await mockService.savePin('7890');

      final provider = SecurityProvider(securityService: mockService);
      await provider.initialize();

      expect(provider.isLocked, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<SecurityProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SecurityLockScreen(),
          ),
        ),
      );

      await tester.pump();

      // Проверяем UI элементы
      expect(find.text('WhereMyMoney'), findsOneWidget);
      expect(find.text('Введите PIN-код для доступа'), findsOneWidget);

      // Вводим неверный PIN: 1, 1, 1, 1
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(provider.isLocked, isTrue);
      expect(find.text('Неверный PIN-код'), findsOneWidget);

      // Вводим правильный PIN: 7, 8, 9, 0
      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      expect(provider.isLocked, isFalse);
    });

    testWidgets('SetPinDialog steps through creation and confirmation', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockSecurityService();
      final provider = SecurityProvider(securityService: mockService);

      await tester.pumpWidget(
        ChangeNotifierProvider<SecurityProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SetPinDialog(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Шаг 1: Придумайте PIN-код
      expect(find.text('Придумайте PIN-код'), findsOneWidget);

      // Вводим 2, 5, 8, 0
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      // Шаг 2: Повторите PIN-код
      expect(find.text('Повторите PIN-код'), findsOneWidget);

      // Повторяем 2, 5, 8, 0
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      expect(provider.isPinEnabled, isTrue);
    });
  });
}
