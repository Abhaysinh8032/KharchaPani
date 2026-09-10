// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mymoney.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Records table
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT,
        to_account_id TEXT,
        notes TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Insert default accounts
    await _insertDefaultAccounts(db);
    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultAccounts(Database db) async {
    final now = DateTime.now().toIso8601String();
    final accounts = [
      {'id': 'acc_card', 'name': 'Card', 'icon': 'card', 'color': 0xFF2196F3, 'balance': 0.0, 'created_at': now},
      {'id': 'acc_cash', 'name': 'Cash', 'icon': 'cash', 'color': 0xFF4CAF50, 'balance': 0.0, 'created_at': now},
      {'id': 'acc_savings', 'name': 'Savings', 'icon': 'savings', 'color': 0xFFFF9800, 'balance': 0.0, 'created_at': now},
    ];
    for (final a in accounts) {
      await db.insert('accounts', a);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    final expenseCategories = [
      {'id': 'cat_baby', 'name': 'Baby', 'icon': 'baby', 'color': 0xFFE91E63, 'type': 'expense'},
      {'id': 'cat_beauty', 'name': 'Beauty', 'icon': 'beauty', 'color': 0xFFD81B60, 'type': 'expense'},
      {'id': 'cat_bills', 'name': 'Bills', 'icon': 'bills', 'color': 0xFF424242, 'type': 'expense'},
      {'id': 'cat_car', 'name': 'Car', 'icon': 'car', 'color': 0xFF7B1FA2, 'type': 'expense'},
      {'id': 'cat_clothing', 'name': 'Clothing', 'icon': 'clothing', 'color': 0xFFEF8C00, 'type': 'expense'},
      {'id': 'cat_data', 'name': 'Data', 'icon': 'data', 'color': 0xFFE53935, 'type': 'expense'},
      {'id': 'cat_education', 'name': 'Education', 'icon': 'education', 'color': 0xFF1565C0, 'type': 'expense'},
      {'id': 'cat_electronics', 'name': 'Electronics', 'icon': 'electronics', 'color': 0xFF00695C, 'type': 'expense'},
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'icon': 'entertainment', 'color': 0xFF6A1B9A, 'type': 'expense'},
      {'id': 'cat_family', 'name': 'Family', 'icon': 'family', 'color': 0xFFAD1457, 'type': 'expense'},
      {'id': 'cat_food', 'name': 'Food', 'icon': 'food', 'color': 0xFFC62828, 'type': 'expense'},
      {'id': 'cat_friends', 'name': 'Friends', 'icon': 'friends', 'color': 0xFF880E4F, 'type': 'expense'},
      {'id': 'cat_health', 'name': 'Health', 'icon': 'health', 'color': 0xFFBF360C, 'type': 'expense'},
      {'id': 'cat_home', 'name': 'Home', 'icon': 'home', 'color': 0xFFAD1457, 'type': 'expense'},
      {'id': 'cat_insurance', 'name': 'Insurance', 'icon': 'insurance', 'color': 0xFFE65100, 'type': 'expense'},
      {'id': 'cat_knowledge', 'name': 'Knowledge', 'icon': 'knowledge', 'color': 0xFFF57F17, 'type': 'expense'},
      {'id': 'cat_selfcare', 'name': 'Self care', 'icon': 'selfcare', 'color': 0xFF6A1B9A, 'type': 'expense'},
      {'id': 'cat_shopping', 'name': 'Shopping', 'icon': 'shopping', 'color': 0xFF1565C0, 'type': 'expense'},
      {'id': 'cat_social', 'name': 'Social', 'icon': 'social', 'color': 0xFF1B5E20, 'type': 'expense'},
      {'id': 'cat_sport', 'name': 'Sport', 'icon': 'sport', 'color': 0xFF1B5E20, 'type': 'expense'},
      {'id': 'cat_tax', 'name': 'Tax', 'icon': 'tax', 'color': 0xFFBF360C, 'type': 'expense'},
      {'id': 'cat_telephone', 'name': 'Telephone', 'icon': 'telephone', 'color': 0xFF558B2F, 'type': 'expense'},
      {'id': 'cat_transport', 'name': 'Transportation', 'icon': 'transportation', 'color': 0xFF1565C0, 'type': 'expense'},
    ];

    final incomeCategories = [
      {'id': 'cat_awards', 'name': 'Awards', 'icon': 'awards', 'color': 0xFF1565C0, 'type': 'income'},
      {'id': 'cat_coupons', 'name': 'Coupons', 'icon': 'coupons', 'color': 0xFFC62828, 'type': 'income'},
      {'id': 'cat_grants', 'name': 'Grants', 'icon': 'grants', 'color': 0xFF2E7D32, 'type': 'income'},
      {'id': 'cat_lottery', 'name': 'Lottery', 'icon': 'lottery', 'color': 0xFFC62828, 'type': 'income'},
      {'id': 'cat_refunds', 'name': 'Refunds', 'icon': 'refunds', 'color': 0xFF2E7D32, 'type': 'income'},
      {'id': 'cat_rental', 'name': 'Rental', 'icon': 'rental', 'color': 0xFF6A1B9A, 'type': 'income'},
      {'id': 'cat_salary', 'name': 'Salary', 'icon': 'salary', 'color': 0xFFAD1457, 'type': 'income'},
      {'id': 'cat_sale', 'name': 'Sale', 'icon': 'sale', 'color': 0xFF2E7D32, 'type': 'income'},
    ];

    for (final c in [...expenseCategories, ...incomeCategories]) {
      await db.insert('categories', {...c, 'created_at': now});
    }
  }
}
