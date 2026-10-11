import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../database/database_helper.dart';
import '../../models/inventory_item.dart';
import '../inventory_repository.dart';

/// SQLite-backed implementation of [InventoryRepository].
class SqliteInventoryRepository implements InventoryRepository {
  final DatabaseHelper _dbHelper;

  SqliteInventoryRepository(this._dbHelper);

  @override
  Future<List<InventoryItem>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableInventoryItems,
      orderBy: 'category ASC, name ASC',
    );
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  @override
  Future<InventoryItem?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableInventoryItems,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }

  @override
  Future<void> insert(InventoryItem item) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.tableInventoryItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(InventoryItem item) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableInventoryItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableInventoryItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updatePackageCount(String id, double newCount) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableInventoryItems,
      {'package_count': newCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
