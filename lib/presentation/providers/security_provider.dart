import 'package:flutter/foundation.dart';
import '../../core/services/security_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityService _securityService;

  bool _isInitialized = false;
  bool _isLocked = false;
  bool _isPinEnabled = false;
  bool _isBiometricsEnabled = false;
  bool _isBiometricsAvailable = false;
  String? _errorMessage;

  SecurityProvider({SecurityService? securityService})
      : _securityService = securityService ?? SecurityService();

  bool get isInitialized => _isInitialized;
  bool get isLocked => _isLocked;
  bool get isPinEnabled => _isPinEnabled;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get isBiometricsAvailable => _isBiometricsAvailable;
  String? get errorMessage => _errorMessage;

  /// Инициализация состояния безопасности при запуске приложения
  Future<void> initialize() async {
    try {
      _isBiometricsAvailable = await _securityService.isBiometricsAvailable();
      _isPinEnabled = await _securityService.isPinEnabled();
      _isBiometricsEnabled = await _securityService.isBiometricsEnabled();

      // Если PIN включен, при запуске приложение всегда заблокировано
      if (_isPinEnabled) {
        _isLocked = true;
      } else {
        _isLocked = false;
      }

      _isInitialized = true;
      notifyListeners();

      // Если включена биометрия, пробуем запросить её при старте
      if (_isLocked && _isBiometricsEnabled && _isBiometricsAvailable) {
        await unlockWithBiometrics();
      }
    } catch (e) {
      _errorMessage = 'Ошибка инициализации безопасности: $e';
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Разблокировка через PIN-код
  Future<bool> unlockWithPin(String pin) async {
    _errorMessage = null;
    final isValid = await _securityService.checkPin(pin);
    if (isValid) {
      _isLocked = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Неверный PIN-код';
      notifyListeners();
      return false;
    }
  }

  /// Разблокировка через биометрию (отпечаток / Face ID)
  Future<bool> unlockWithBiometrics() async {
    if (!_isBiometricsEnabled || !_isBiometricsAvailable) return false;

    _errorMessage = null;
    final success = await _securityService.authenticateBiometrically();
    if (success) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Установка или смена PIN-кода
  Future<void> setPin(String newPin) async {
    await _securityService.savePin(newPin);
    _isPinEnabled = true;
    _isLocked = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Отключение защиты PIN-кодом
  Future<void> removePin() async {
    await _securityService.removePin();
    _isPinEnabled = false;
    _isBiometricsEnabled = false;
    _isLocked = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Переключение разрешения биометрии
  Future<void> toggleBiometrics(bool enabled) async {
    await _securityService.setBiometricsEnabled(enabled);
    _isBiometricsEnabled = enabled;
    notifyListeners();
  }

  /// Принудительная блокировка приложения
  void lockApp() {
    if (_isPinEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Срабатывает при возврате приложения из фонового режима (resumed)
  Future<void> onAppResumed() async {
    if (_isPinEnabled && !_isLocked) {
      _isLocked = true;
      notifyListeners();

      if (_isBiometricsEnabled && _isBiometricsAvailable) {
        await unlockWithBiometrics();
      }
    }
  }
}
