import '../core/helpers.dart';

/// Configurable costing profile attached to a product (cake).
///
/// Contains labor, packaging, and overhead factors used in calculating
/// Cost of Goods Sold (COGS), True Cost, and Profit Margins.
class ProductCostingProfile {
  final String id;
  final String productId;
  final int prepTimeMinutes; // Total preparation & baking labor minutes
  final double hourlyLaborRate; // PHP per hour (e.g. 75.00)
  final double packagingCost; // Box, cake board, ribbon, sticker cost
  final double overheadFixedCost; // Electricity, gas, water allocation
  final double targetMarginPct; // e.g. 40.0 for 40% target profit margin
  final DateTime updatedAt;

  ProductCostingProfile({
    String? id,
    required this.productId,
    this.prepTimeMinutes = 0,
    this.hourlyLaborRate = 0.0,
    this.packagingCost = 0.0,
    this.overheadFixedCost = 0.0,
    this.targetMarginPct = 40.0,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Direct labor cost calculated from prep minutes and hourly rate.
  double get laborCost {
    if (prepTimeMinutes <= 0 || hourlyLaborRate <= 0) return 0.0;
    return (prepTimeMinutes / 60.0) * hourlyLaborRate;
  }

  /// Total non-ingredient operational cost (Labor + Packaging + Overhead).
  double get nonIngredientCost =>
      laborCost + packagingCost + overheadFixedCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'prep_time_minutes': prepTimeMinutes,
      'hourly_labor_rate': hourlyLaborRate,
      'packaging_cost': packagingCost,
      'overhead_fixed_cost': overheadFixedCost,
      'target_margin_pct': targetMarginPct,
      'updated_at': toDbString(updatedAt),
    };
  }

  factory ProductCostingProfile.fromMap(Map<String, dynamic> map) {
    return ProductCostingProfile(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      prepTimeMinutes: (map['prep_time_minutes'] as num?)?.toInt() ?? 0,
      hourlyLaborRate: (map['hourly_labor_rate'] as num?)?.toDouble() ?? 0.0,
      packagingCost: (map['packaging_cost'] as num?)?.toDouble() ?? 0.0,
      overheadFixedCost: (map['overhead_fixed_cost'] as num?)?.toDouble() ?? 0.0,
      targetMarginPct: (map['target_margin_pct'] as num?)?.toDouble() ?? 40.0,
      updatedAt: map['updated_at'] != null
          ? fromDbString(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  ProductCostingProfile copyWith({
    int? prepTimeMinutes,
    double? hourlyLaborRate,
    double? packagingCost,
    double? overheadFixedCost,
    double? targetMarginPct,
    DateTime? updatedAt,
  }) {
    return ProductCostingProfile(
      id: id,
      productId: productId,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      hourlyLaborRate: hourlyLaborRate ?? this.hourlyLaborRate,
      packagingCost: packagingCost ?? this.packagingCost,
      overheadFixedCost: overheadFixedCost ?? this.overheadFixedCost,
      targetMarginPct: targetMarginPct ?? this.targetMarginPct,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ProductCostingProfile(product: $productId, prep: ${prepTimeMinutes}m @ ₱$hourlyLaborRate/h, pack: ₱$packagingCost, overhead: ₱$overheadFixedCost)';
}
