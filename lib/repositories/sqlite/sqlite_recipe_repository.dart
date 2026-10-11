import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import '../recipe_repository.dart';

/// SQLite-backed implementation of [RecipeRepository].
///
/// Recipes are stored across two tables: `recipes` (header) and
/// `recipe_items` (ingredients).  The [save] method uses a transaction
/// to atomically replace all items whenever a recipe is saved.
class SqliteRecipeRepository implements RecipeRepository {
  final DatabaseHelper _dbHelper;

  SqliteRecipeRepository(this._dbHelper);

  @override
  Future<Recipe?> getByProductId(String productId) async {
    final db = await _dbHelper.database;

    // Fetch recipe header
    final recipeMaps = await db.query(
      AppConstants.tableRecipes,
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (recipeMaps.isEmpty) return null;

    final recipeMap = recipeMaps.first;
    final recipeId = recipeMap['id'] as String;

    // Fetch associated recipe items
    final itemMaps = await db.query(
      AppConstants.tableRecipeItems,
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'ingredient_name ASC',
    );

    final items = itemMaps.map((m) => RecipeItem.fromMap(m)).toList();
    return Recipe.fromMap(recipeMap, items: items);
  }

  @override
  Future<void> save(Recipe recipe) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Delete any existing recipe for the same product
      // (one recipe per product policy)
      final existing = await txn.query(
        AppConstants.tableRecipes,
        columns: ['id'],
        where: 'product_id = ?',
        whereArgs: [recipe.productId],
      );

      for (final row in existing) {
        final existingId = row['id'] as String;
        await txn.delete(
          AppConstants.tableRecipeItems,
          where: 'recipe_id = ?',
          whereArgs: [existingId],
        );
        await txn.delete(
          AppConstants.tableRecipes,
          where: 'id = ?',
          whereArgs: [existingId],
        );
      }

      // Insert new recipe header
      await txn.insert(
        AppConstants.tableRecipes,
        recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert all recipe items
      for (final item in recipe.items) {
        await txn.insert(
          AppConstants.tableRecipeItems,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> updateItemChecked(String itemId, bool isChecked) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableRecipeItems,
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Delete items first, then header
      await txn.delete(
        AppConstants.tableRecipeItems,
        where: 'recipe_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        AppConstants.tableRecipes,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
