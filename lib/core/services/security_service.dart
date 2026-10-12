import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/database/app_database.dart';

class SecurityService {
  final LocalAuthentication _auth;
  final AppDatabase _dbProvider;

  SecurityService({
    LocalAuthentication? auth,
    AppDatabase? dbProvider,
  })  : _auth = auth ?? LocalAuthentication(),
        _dbProvider = dbProvider ?? AppDatabase.instance;

  // Ключи настроек в таблице app_settings
  static const String keyPinHash = 'security_pin_hash';
  static const String keyPinSalt = 'security_pin_salt';
  static const String keyPinEnabled = 'security_pin_enabled';
  static const String keyBiometricsEnabled = 'security_biometrics_enabled';

  /// Генерация криптографически стойкой соли
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Получение хеша PIN-кода (SHA-256 с солью)
  static String hashPin(String pin, String salt) {
    final payload = utf8.encode('$salt:$pin');
    return sha256.convert(payload).toString();
  }

  /// Проверка введенного PIN с сохраненным хешем
  static bool verifyPinHash(String pin, String salt, String expectedHash) {
    final computed = hashPin(pin, salt);
    return computed == expectedHash;
  }

  // ================= РАБОТА С БАЗОЙ НАСТРОЕК =================

  Future<String?> getSetting(String key) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _dbProvider.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSetting(String key) async {
    final db = await _dbProvider.database;
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Проверка, включен ли PIN-код
  Future<bool> isPinEnabled() async {
    final enabled = await getSetting(keyPinEnabled);
    if (enabled != '1') return false;
    final hash = await getSetting(keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Проверка, включен ли вход по биометрии
  Future<bool> isBiometricsEnabled() async {
    final pinActive = await isPinEnabled();
    if (!pinActive) return false;
    final enabled = await getSetting(keyBiometricsEnabled);
    return enabled == '1';
  }

  /// Сохранение нового PIN-кода
  Future<void> savePin(String pin) async {
    final salt = generateSalt();
    final hash = hashPin(pin, salt);

    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.insert(
        'app_settings',
        {'key': keyPinSalt, 'value': salt},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'app_settings',
        {'key': keyPinHash, 'value': hash},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'app_settings',
        {'key': keyPinEnabled, 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Валидация введенного PIN-кода
  Future<bool> checkPin(String pin) async {
    final salt = await getSetting(keyPinSalt);
    final expectedHash = await getSetting(keyPinHash);

    if (salt == null || expectedHash == null) {
      return false;
    }

    return verifyPinHash(pin, salt, expectedHash);
  }

  /// Полное удаление PIN-кода и отключение биометрии
  Future<void> removePin() async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete('app_settings', where: 'key IN (?, ?, ?, ?)', whereArgs: [
        keyPinHash,
        keyPinSalt,
        keyPinEnabled,
        keyBiometricsEnabled,
      ]);
    });
  }

  /// Включение или отключение биометрии
  Future<void> setBiometricsEnabled(bool enabled) async {
    await setSetting(keyBiometricsEnabled, enabled ? '1' : '0');
  }

  // ================= БИОМЕТРИЯ (LOCAL_AUTH) =================

  /// Проверка, поддерживает ли устройство биометрию
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('Biometrics check error: $e');
      return false;
    }
  }

  /// Доступные типы биометрии (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Available biometrics error: $e');
      return [];
    }
  }

  /// Вызов нативного системного окна аутентификации
  Future<bool> authenticateBiometrically({
    String localizedReason = 'Подтвердите личность для входа в WhereMyMoney',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }
}
