import 'package:flutter/foundation.dart';

import '../core/helpers.dart';
import '../models/inventory_item.dart';
import '../models/product_cost_breakdown.dart';
import '../models/product_costing_profile.dart';
import '../repositories/costing_profile_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/recipe_repository.dart';

/// Service computing dynamic product costs, margins, and suggested pricing.
///
/// Reacts to changes in raw ingredient package costs from inventory without
/// coupling to physical stock quantity movements.
class CostingService extends ChangeNotifier {
  final ProductRepository _productRepo;
  final RecipeRepository _recipeRepo;
  final InventoryRepository _inventoryRepo;
  final CostingProfileRepository _costingProfileRepo;

  List<ProductCostBreakdown> _breakdowns = [];
  bool _isLoading = false;

  CostingService({
    required ProductRepository productRepo,
    required RecipeRepository recipeRepo,
    required InventoryRepository inventoryRepo,
    required CostingProfileRepository costingProfileRepo,
  })  : _productRepo = productRepo,
        _recipeRepo = recipeRepo,
        _inventoryRepo = inventoryRepo,
        _costingProfileRepo = costingProfileRepo;

  List<ProductCostBreakdown> get breakdowns => List.unmodifiable(_breakdowns);
  bool get isLoading => _isLoading;

  /// Average profit margin % across all active products that have recipes/costs.
  double get averageProfitMarginPct {
    if (_breakdowns.isEmpty) return 0.0;
    final totalMargin = _breakdowns.fold(0.0, (sum, b) => sum + b.profitMarginPct);
    return totalMargin / _breakdowns.length;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Recalculates and loads all cost breakdowns.
  Future<void> loadCostings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final products = await _productRepo.getAll();
      final inventoryItems = await _inventoryRepo.getAll();
      final inventoryMap = {for (final item in inventoryItems) item.id: item};
      final profilesMap = await _costingProfileRepo.getAllProfiles();

      final list = <ProductCostBreakdown>[];

      for (final product in products) {
        final recipe = await _recipeRepo.getByProductId(product.id);
        final profile = profilesMap[product.id] ??
            ProductCostingProfile(productId: product.id);

        final itemCosts = <RecipeItemCost>[];
        if (recipe != null) {
          for (final item in recipe.items) {
            InventoryItem? linkedInv;
            if (item.inventoryItemId != null) {
              linkedInv = inventoryMap[item.inventoryItemId];
            }

            // Fallback smart matching by ingredient name/brand if not explicitly linked
            if (linkedInv == null) {
              final query = item.ingredientName.trim().toLowerCase();
              final candidates = inventoryMap.values.where((inv) {
                final invName = inv.name.toLowerCase();
                final invBrand = inv.brand.toLowerCase();
                return invName == query ||
                    invName.contains(query) ||
                    query.contains(invName) ||
                    '$invBrand $invName'.contains(query);
              }).toList();

              if (candidates.isNotEmpty) {
                // Prioritize candidate with stock on hand first, else first match
                linkedInv = candidates.firstWhere(
                  (c) => c.packageCount > 0,
                  orElse: () => candidates.first,
                );
              }
            }

            double subtotal = 0.0;
            double unitCost = 0.0;

            if (linkedInv != null) {
              unitCost = linkedInv.costPerUnit;
              final convertedQty = convertMeasurementUnit(
                item.quantity,
                item.unit,
                linkedInv.measurementUnit,
              );
              subtotal = convertedQty * unitCost;
            }

            itemCosts.add(
              RecipeItemCost(
                item: item,
                linkedInventoryItem: linkedInv,
                unitCost: unitCost,
                subtotalCost: subtotal,
              ),
            );
          }
        }

        list.add(
          ProductCostBreakdown(
            product: product,
            recipe: recipe,
            itemCosts: itemCosts,
            profile: profile,
          ),
        );
      }

      _breakdowns = list;
    } catch (e, stack) {
      debugPrint('CostingService error loading costings: $e\n$stack');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves or updates the costing profile (labor, overhead, target margin) for a product.
  Future<void> saveProfile(ProductCostingProfile profile) async {
    await _costingProfileRepo.save(profile);
    await loadCostings();
  }

  /// Gets breakdown for a specific product ID.
  ProductCostBreakdown? getBreakdownForProduct(String productId) {
    try {
      return _breakdowns.firstWhere((b) => b.product.id == productId);
    } catch (_) {
      return null;
    }
  }
}
