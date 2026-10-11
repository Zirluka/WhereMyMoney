import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'initial_data.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Инициализация FFI для настольных ОС (Windows / Linux / macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appSupportDir = await getApplicationSupportDirectory();
      dbPath = p.join(appSupportDir.path, 'WhereMyMoney', 'wheremymoney.db');
      final dir = Directory(p.dirname(dbPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'wheremymoney.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица счетов
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'RUB',
        color_hex INTEGER NOT NULL,
        icon_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Таблица категорий
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Таблица транзакций
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        qr_raw_data TEXT,
        target_account_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      );
    ''');

    // Индексы для высокой производительности при больших объемах данных
    await db.execute('CREATE INDEX idx_transactions_date ON transactions (date);');
    await db.execute('CREATE INDEX idx_transactions_account ON transactions (account_id);');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions (category_id);');
    await db.execute('CREATE INDEX idx_transactions_is_deleted ON transactions (is_deleted);');

    // Сидирование начальных данных
    final batch = db.batch();
    for (final account in InitialData.getDefaultAccounts()) {
      batch.insert('accounts', account.toMap());
    }
    for (final category in InitialData.getDefaultCategories()) {
      batch.insert('categories', category.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
