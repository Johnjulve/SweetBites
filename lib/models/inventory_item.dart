import '../core/helpers.dart';

/// Represents a pantry / raw material stock item in SweetBites.
///
/// Designed to capture both physical inventory count:
/// `[5x] Evap Milk [Nestle] [360ml]`
/// and the unit cost reference for recipe costing calculations:
/// `costPerUnit = packageCost / packageSize`.
class InventoryItem {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String packageType; // e.g. 'Can', 'Bottle', 'Pack', 'Sachet', 'Box', 'Pouch', 'Bar', 'Tub', 'Piece'
  final double packageCount; // e.g. 5 cans/packs
  final double packageSize; // e.g. 360 (net content per package)
  final String measurementUnit; // e.g. 'ml', 'g', 'pcs'
  final double packageCost; // e.g. 39.45 PHP per package
  final double minStockAlert; // e.g. alert if <= 2 packages
  final DateTime updatedAt;

  InventoryItem({
    String? id,
    required this.name,
    this.brand = '',
    required this.category,
    this.packageType = 'Pack',
    this.packageCount = 0.0,
    required this.packageSize,
    required this.measurementUnit,
    required this.packageCost,
    this.minStockAlert = 0.0,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Normalized package type name (e.g. 'Can', 'Bottle', 'Pack', 'Sachet').
  String get packageTypeLabel =>
      packageType.trim().isEmpty ? 'Pack' : packageType.trim();

  /// Pluralized package type (e.g. 'cans', 'bottles', 'sachets', 'boxes', 'packs').
  String get packageTypePlural {
    final lower = packageTypeLabel.toLowerCase();
    if (lower == 'box') return 'boxes';
    if (lower == 'pouch') return 'pouches';
    if (lower == 'piece') return 'pieces';
    if (lower.endsWith('s')) return packageTypeLabel;
    return '${packageTypeLabel}s';
  }

  /// Cost per single measurement unit (e.g. PHP per ml or per gram).
  /// Guard against division by zero.
  double get costPerUnit {
    if (packageSize <= 0) return 0.0;
    return packageCost / packageSize;
  }

  /// Total physical units in stock (e.g. 5 cans * 360ml = 1800ml).
  double get totalStockUnits => packageCount * packageSize;

  /// Total value of this inventory on hand (e.g. 5 cans * 39.45 PHP = 197.25 PHP).
  double get totalValue => packageCount * packageCost;

  /// Whether current physical stock is at or below the minimum threshold.
  bool get isLowStock => minStockAlert > 0 && packageCount <= minStockAlert;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'package_type': packageTypeLabel,
      'package_count': packageCount,
      'package_size': packageSize,
      'measurement_unit': measurementUnit,
      'package_cost': packageCost,
      'min_stock_alert': minStockAlert,
      'updated_at': toDbString(updatedAt),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String,
      packageType: (map['package_type'] as String?)?.trim().isNotEmpty == true
          ? (map['package_type'] as String)
          : 'Pack',
      packageCount: (map['package_count'] as num?)?.toDouble() ?? 0.0,
      packageSize: (map['package_size'] as num?)?.toDouble() ?? 1.0,
      measurementUnit: map['measurement_unit'] as String? ?? '',
      packageCost: (map['package_cost'] as num?)?.toDouble() ?? 0.0,
      minStockAlert: (map['min_stock_alert'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updated_at'] != null
          ? fromDbString(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  InventoryItem copyWith({
    String? name,
    String? brand,
    String? category,
    String? packageType,
    double? packageCount,
    double? packageSize,
    String? measurementUnit,
    double? packageCost,
    double? minStockAlert,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      packageType: packageType ?? this.packageType,
      packageCount: packageCount ?? this.packageCount,
      packageSize: packageSize ?? this.packageSize,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      packageCost: packageCost ?? this.packageCost,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'InventoryItem([${packageCount}x] $name ${brand.isNotEmpty ? "[$brand] " : ""}[$packageSize$measurementUnit] @ ₱$packageCost)';
}
