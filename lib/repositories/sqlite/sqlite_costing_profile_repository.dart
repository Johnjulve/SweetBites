import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../database/database_helper.dart';
import '../../models/product_costing_profile.dart';
import '../costing_profile_repository.dart';

/// SQLite-backed implementation of [CostingProfileRepository].
class SqliteCostingProfileRepository implements CostingProfileRepository {
  final DatabaseHelper _dbHelper;

  SqliteCostingProfileRepository(this._dbHelper);

  @override
  Future<ProductCostingProfile?> getByProductId(String productId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableProductCostingProfiles,
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductCostingProfile.fromMap(maps.first);
  }

  @override
  Future<Map<String, ProductCostingProfile>> getAllProfiles() async {
    final db = await _dbHelper.database;
    final maps = await db.query(AppConstants.tableProductCostingProfiles);
    final result = <String, ProductCostingProfile>{};
    for (final map in maps) {
      final profile = ProductCostingProfile.fromMap(map);
      result[profile.productId] = profile;
    }
    return result;
  }

  @override
  Future<void> save(ProductCostingProfile profile) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.tableProductCostingProfiles,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String productId) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableProductCostingProfiles,
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }
}
