import '../core/helpers.dart';

/// A recipe linked to a specific product, containing a list of ingredients.
class Recipe {
  final String id;
  final String productId;
  final DateTime createdAt;
  final List<RecipeItem> items;

  Recipe({
    String? id,
    required this.productId,
    DateTime? createdAt,
    this.items = const [],
  })  : id = id ?? generateId(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'created_at': toDbString(createdAt),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map, {List<RecipeItem>? items}) {
    return Recipe(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      createdAt: fromDbString(map['created_at'] as String),
      items: items ?? [],
    );
  }

  Recipe copyWith({
    List<RecipeItem>? items,
  }) {
    return Recipe(
      id: id,
      productId: productId,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'Recipe(id: $id, productId: $productId, items: ${items.length})';
}

/// An individual ingredient within a recipe.
class RecipeItem {
  final String id;
  final String recipeId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final bool isChecked;
  final String? inventoryItemId;

  RecipeItem({
    String? id,
    required this.recipeId,
    required this.ingredientName,
    this.quantity = 0,
    this.unit = '',
    this.isChecked = false,
    this.inventoryItemId,
  }) : id = id ?? generateId();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'is_checked': isChecked ? 1 : 0,
      'inventory_item_id': inventoryItemId,
    };
  }

  factory RecipeItem.fromMap(Map<String, dynamic> map) {
    return RecipeItem(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      ingredientName: map['ingredient_name'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      isChecked: (map['is_checked'] as int? ?? 0) == 1,
      inventoryItemId: map['inventory_item_id'] as String?,
    );
  }

  RecipeItem copyWith({
    String? ingredientName,
    double? quantity,
    String? unit,
    bool? isChecked,
    String? inventoryItemId,
  }) {
    return RecipeItem(
      id: id,
      recipeId: recipeId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
    );
  }

  @override
  String toString() =>
      'RecipeItem(name: $ingredientName, qty: $quantity $unit, invId: $inventoryItemId)';
}
