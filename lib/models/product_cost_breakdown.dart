import 'inventory_item.dart';
import 'product.dart';
import 'product_costing_profile.dart';
import 'recipe.dart';

/// Itemized cost breakdown for a single recipe line.
class RecipeItemCost {
  final RecipeItem item;
  final InventoryItem? linkedInventoryItem;
  final double unitCost;
  final double subtotalCost;

  RecipeItemCost({
    required this.item,
    this.linkedInventoryItem,
    required this.unitCost,
    required this.subtotalCost,
  });
}

/// Comprehensive dynamic costing evaluation for a single cake product.
class ProductCostBreakdown {
  final Product product;
  final Recipe? recipe;
  final List<RecipeItemCost> itemCosts;
  final ProductCostingProfile profile;

  ProductCostBreakdown({
    required this.product,
    this.recipe,
    required this.itemCosts,
    required this.profile,
  });

  /// Cost of raw materials / ingredients.
  double get ingredientCost =>
      itemCosts.fold(0.0, (sum, i) => sum + i.subtotalCost);

  /// Direct labor cost.
  double get laborCost => profile.laborCost;

  /// Packaging cost (box, ribbon, etc.).
  double get packagingCost => profile.packagingCost;

  /// Overhead buffer (gas, electricity, etc.).
  double get overheadCost => profile.overheadFixedCost;

  /// Total cost of production (COGS + Labor + Packaging + Overhead).
  double get totalCost =>
      ingredientCost + laborCost + packagingCost + overheadCost;

  /// Actual selling price of the cake.
  double get sellingPrice => product.price;

  /// Net profit in PHP per cake sold.
  double get netProfit => sellingPrice - totalCost;

  /// Net profit margin percentage based on selling price.
  /// Guard against zero selling price.
  double get profitMarginPct {
    if (sellingPrice <= 0) return 0.0;
    return (netProfit / sellingPrice) * 100.0;
  }

  /// Markup percentage over total production cost.
  double get markupPct {
    if (totalCost <= 0) return 0.0;
    return (netProfit / totalCost) * 100.0;
  }

  /// Suggested selling price to achieve the profile's target margin %.
  /// Formula: Total Cost / (1 - (Target Margin % / 100))
  double get suggestedPrice {
    final target = profile.targetMarginPct;
    if (target >= 100.0 || target < 0) return totalCost;
    final marginFraction = target / 100.0;
    final divisor = 1.0 - marginFraction;
    if (divisor <= 0) return totalCost;
    return totalCost / divisor;
  }
}
