import '../models/recipe.dart';

/// Abstract interface for recipe data operations.
abstract class RecipeRepository {
  Future<Recipe?> getByProductId(String productId);
  Future<void> save(Recipe recipe);
  Future<void> delete(String id);
  Future<void> updateItemChecked(String itemId, bool isChecked);
}
