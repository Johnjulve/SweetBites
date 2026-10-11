import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';

/// Singleton helper that manages the SQLite database lifecycle.
///
/// Opens (or creates) the database on first access and exposes it
/// through the [database] getter.  All table DDL and seed data are
/// executed inside [_onCreate].
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// Returns the open database, creating it on first call.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ---------------------------------------------------------------------------
  // Database initialisation
  // ---------------------------------------------------------------------------

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return databaseFactory.openDatabase(
        AppConstants.databaseName,
        options: OpenDatabaseOptions(
          version: AppConstants.databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, AppConstants.databaseName);

    return openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  /// Enable foreign-key enforcement for every connection.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Handle database schema upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppConstants.tablePayments} ADD COLUMN is_voided INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      // 1. Add inventory_item_id to recipe_items
      await db.execute(
        'ALTER TABLE ${AppConstants.tableRecipeItems} ADD COLUMN inventory_item_id TEXT',
      );

      // 2. Create inventory_items table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableInventoryItems} (
          id                TEXT PRIMARY KEY,
          name              TEXT NOT NULL,
          brand             TEXT,
          category          TEXT NOT NULL,
          package_count     REAL NOT NULL DEFAULT 0,
          package_size      REAL NOT NULL,
          measurement_unit  TEXT NOT NULL,
          package_cost      REAL NOT NULL,
          min_stock_alert   REAL NOT NULL DEFAULT 0,
          updated_at        TEXT NOT NULL
        )
      ''');

      // 3. Create product_costing_profiles table
      await db.execute('''
        CREATE TABLE ${AppConstants.tableProductCostingProfiles} (
          id                  TEXT PRIMARY KEY,
          product_id          TEXT NOT NULL UNIQUE,
          prep_time_minutes   INTEGER NOT NULL DEFAULT 0,
          hourly_labor_rate   REAL NOT NULL DEFAULT 0,
          packaging_cost      REAL NOT NULL DEFAULT 0,
          overhead_fixed_cost REAL NOT NULL DEFAULT 0,
          target_margin_pct   REAL NOT NULL DEFAULT 40.0,
          updated_at          TEXT NOT NULL,
            ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${AppConstants.tableInventoryItems} ADD COLUMN package_type TEXT NOT NULL DEFAULT "Pack"',
      );
    }
  }

  /// Create all tables and insert seed data.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ---- customers ---------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableCustomers} (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        phone       TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    // ---- products ----------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableProducts} (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        price       REAL NOT NULL,
        description TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT NOT NULL
      )
    ''');

    // ---- recipes -----------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableRecipes} (
        id          TEXT PRIMARY KEY,
        product_id  TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.tableProducts}(id)
          ON DELETE CASCADE
      )
    ''');

    // ---- recipe_items ------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableRecipeItems} (
        id                TEXT PRIMARY KEY,
        recipe_id         TEXT NOT NULL,
        ingredient_name   TEXT NOT NULL,
        quantity          REAL NOT NULL DEFAULT 0,
        unit              TEXT,
        is_checked        INTEGER NOT NULL DEFAULT 0,
        inventory_item_id TEXT,
        FOREIGN KEY (recipe_id) REFERENCES ${AppConstants.tableRecipes}(id)
          ON DELETE CASCADE
      )
    ''');

    // ---- orders ------------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableOrders} (
        id            TEXT PRIMARY KEY,
        customer_id   TEXT NOT NULL,
        total_amount  REAL NOT NULL,
        status        TEXT NOT NULL DEFAULT 'pending',
        pickup_date   TEXT NOT NULL,
        notes         TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.tableCustomers}(id)
          ON DELETE CASCADE
      )
    ''');

    // ---- order_items -------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableOrderItems} (
        id          TEXT PRIMARY KEY,
        order_id    TEXT NOT NULL,
        product_id  TEXT NOT NULL,
        quantity    INTEGER NOT NULL,
        unit_price  REAL NOT NULL,
        subtotal    REAL NOT NULL,
        FOREIGN KEY (order_id)   REFERENCES ${AppConstants.tableOrders}(id)
          ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.tableProducts}(id)
          ON DELETE CASCADE
      )
    ''');

    // ---- payments ----------------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tablePayments} (
        id              TEXT PRIMARY KEY,
        order_id        TEXT NOT NULL,
        amount_paid     REAL NOT NULL,
        payment_method  TEXT NOT NULL DEFAULT 'cash',
        notes           TEXT,
        paid_at         TEXT NOT NULL,
        is_voided       INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES ${AppConstants.tableOrders}(id)
          ON DELETE CASCADE
      )
    ''');

    // ---- inventory_items ---------------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableInventoryItems} (
        id                TEXT PRIMARY KEY,
        name              TEXT NOT NULL,
        brand             TEXT,
        category          TEXT NOT NULL,
        package_type      TEXT NOT NULL DEFAULT 'Pack',
        package_count     REAL NOT NULL DEFAULT 0,
        package_size      REAL NOT NULL,
        measurement_unit  TEXT NOT NULL,
        package_cost      REAL NOT NULL,
        min_stock_alert   REAL NOT NULL DEFAULT 0,
        updated_at        TEXT NOT NULL
      )
    ''');

    // ---- product_costing_profiles ------------------------------------------
    batch.execute('''
      CREATE TABLE ${AppConstants.tableProductCostingProfiles} (
        id                  TEXT PRIMARY KEY,
        product_id          TEXT NOT NULL UNIQUE,
        prep_time_minutes   INTEGER NOT NULL DEFAULT 0,
        hourly_labor_rate   REAL NOT NULL DEFAULT 0,
        packaging_cost      REAL NOT NULL DEFAULT 0,
        overhead_fixed_cost REAL NOT NULL DEFAULT 0,
        target_margin_pct   REAL NOT NULL DEFAULT 40.0,
        updated_at          TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.tableProducts}(id)
          ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);

    // ---- Seed sample products ----------------------------------------------
    await _seedProducts(db);
    await _seedInventory(db);
  }

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  Future<void> _seedProducts(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();

    final sampleProducts = <Map<String, dynamic>>[
      {
        'id': uuid.v4(),
        'name': 'Classic Chocolate Cake',
        'price': 850.0,
        'description': 'Rich and decadent chocolate cake with dark chocolate ganache.',
        'is_active': 1,
        'created_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Vanilla Buttercream Cake',
        'price': 750.0,
        'description': 'Light vanilla sponge layered with smooth buttercream frosting.',
        'is_active': 1,
        'created_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Red Velvet Cake',
        'price': 900.0,
        'description': 'Velvety red cake with cream cheese frosting.',
        'is_active': 1,
        'created_at': now,
      },
    ];

    final seedBatch = db.batch();
    for (final product in sampleProducts) {
      seedBatch.insert(AppConstants.tableProducts, product);
    }
    await seedBatch.commit(noResult: true);
  }

  Future<void> _seedInventory(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();

    final sampleItems = <Map<String, dynamic>>[
      {
        'id': uuid.v4(),
        'name': 'Evaporated Milk',
        'brand': 'Nestle',
        'category': 'Dairy',
        'package_type': 'Can',
        'package_count': 5.0,
        'package_size': 360.0,
        'measurement_unit': 'ml',
        'package_cost': 39.45,
        'min_stock_alert': 2.0,
        'updated_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Cake Flour',
        'brand': 'Maya',
        'category': 'Dry Goods',
        'package_type': 'Pack',
        'package_count': 4.0,
        'package_size': 1000.0,
        'measurement_unit': 'g',
        'package_cost': 65.00,
        'min_stock_alert': 2.0,
        'updated_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Refined White Sugar',
        'brand': 'Victoria',
        'category': 'Dry Goods',
        'package_type': 'Pack',
        'package_count': 3.0,
        'package_size': 1000.0,
        'measurement_unit': 'g',
        'package_cost': 85.00,
        'min_stock_alert': 1.0,
        'updated_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Unsalted Butter',
        'brand': 'Anchor',
        'category': 'Dairy',
        'package_type': 'Bar',
        'package_count': 6.0,
        'package_size': 227.0,
        'measurement_unit': 'g',
        'package_cost': 135.00,
        'min_stock_alert': 2.0,
        'updated_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Fresh Eggs',
        'brand': 'Farm Fresh',
        'category': 'Dairy',
        'package_type': 'Piece',
        'package_count': 30.0,
        'package_size': 1.0,
        'measurement_unit': 'pcs',
        'package_cost': 8.50,
        'min_stock_alert': 10.0,
        'updated_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Pure Cocoa Powder',
        'brand': 'Hershey\'s',
        'category': 'Flavoring',
        'package_type': 'Tub',
        'package_count': 2.0,
        'package_size': 226.0,
        'measurement_unit': 'g',
        'package_cost': 195.00,
        'min_stock_alert': 1.0,
        'updated_at': now,
      },
      {
        'id': uuid.v4(),
        'name': 'Bento Cake Box with Lid',
        'brand': 'EcoPack',
        'category': 'Packaging',
        'package_type': 'Piece',
        'package_count': 50.0,
        'package_size': 1.0,
        'measurement_unit': 'pcs',
        'package_cost': 12.00,
        'min_stock_alert': 15.0,
        'updated_at': now,
      },
    ];

    final seedBatch = db.batch();
    for (final item in sampleItems) {
      seedBatch.insert(AppConstants.tableInventoryItems, item);
    }
    await seedBatch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Convenience wrappers
  // ---------------------------------------------------------------------------

  /// Close the database connection. Useful for testing tear-down.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
