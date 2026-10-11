import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../database/database_helper.dart';
import '../../models/product.dart';
import '../product_repository.dart';

/// SQLite-backed implementation of [ProductRepository].
class SqliteProductRepository implements ProductRepository {
  final DatabaseHelper _dbHelper;

  SqliteProductRepository(this._dbHelper);

  @override
  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  @override
  Future<List<Product>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  @override
  Future<void> insert(Product product) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.tableProducts,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
