import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/recipe.dart';
import '../repositories/product_repository.dart';
import '../repositories/recipe_repository.dart';

/// Service that manages product and recipe state.
///
/// Provides CRUD operations for products and their associated recipes,
/// caching the product list so list screens can render without redundant
/// database queries.
class ProductService extends ChangeNotifier {
  final ProductRepository _productRepo;
  final RecipeRepository _recipeRepo;

  List<Product> _products = [];
  bool _isLoading = false;

  ProductService({
    required ProductRepository productRepo,
    required RecipeRepository recipeRepo,
  })  : _productRepo = productRepo,
        _recipeRepo = recipeRepo;

  // ── Getters ──────────────────────────────────────────────────────

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;

  // ── Product Operations ───────────────────────────────────────────

  /// Loads all products (active and inactive) and notifies listeners.
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _productRepo.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads only active products and notifies listeners.
  Future<void> loadActiveProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _productRepo.getActive();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a single product by [id], or null if not found.
  Future<Product?> getProductById(String id) async {
    return _productRepo.getById(id);
  }

  /// Creates a new product and refreshes the cache.
  Future<void> createProduct(Product product) async {
    await _productRepo.insert(product);
    await loadProducts();
  }

  /// Updates an existing product and refreshes the cache.
  Future<void> updateProduct(Product product) async {
    await _productRepo.update(product);
    await loadProducts();
  }

  /// Deletes a product by [id] and refreshes the cache.
  Future<void> deleteProduct(String id) async {
    await _productRepo.delete(id);
    await loadProducts();
  }

  /// Returns a list of active products directly from the repository.
  Future<List<Product>> getActiveProducts() async {
    return _productRepo.getActive();
  }

  /// Returns a list of all products directly from the repository.
  Future<List<Product>> getAllProducts() async {
    return _productRepo.getAll();
  }

  // ── Recipe Operations ────────────────────────────────────────────

  /// Returns the recipe for a product, or null if none exists.
  Future<Recipe?> getRecipe(String productId) async {
    return _recipeRepo.getByProductId(productId);
  }

  /// Saves (creates or replaces) a recipe for a product.
  Future<void> saveRecipe(Recipe recipe) async {
    await _recipeRepo.save(recipe);
    notifyListeners();
  }

  /// Updates the checked state of a recipe item.
  Future<void> updateRecipeItemChecked(String itemId, bool isChecked) async {
    await _recipeRepo.updateItemChecked(itemId, isChecked);
    notifyListeners();
  }
}
