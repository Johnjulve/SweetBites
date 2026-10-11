import 'package:flutter_test/flutter_test.dart';
import 'package:sweetbites/core/helpers.dart';
import 'package:sweetbites/models/inventory_item.dart';
import 'package:sweetbites/models/product.dart';
import 'package:sweetbites/models/product_cost_breakdown.dart';
import 'package:sweetbites/models/product_costing_profile.dart';
import 'package:sweetbites/models/recipe.dart';

void main() {
  group('Phase 1 - InventoryItem and Costing Calculations', () {
    test('Calculates unit cost from package size and package cost', () {
      // 1 can of Evap Milk = 360ml @ 39.45 PHP
      final evap = InventoryItem(
        name: 'Evaporated Milk',
        brand: 'Nestle',
        category: 'Dairy',
        packageCount: 5.0,
        packageSize: 360.0,
        measurementUnit: 'ml',
        packageCost: 39.45,
      );

      expect(evap.costPerUnit, closeTo(39.45 / 360.0, 0.0001));
      expect(evap.totalStockUnits, equals(1800.0));
      expect(evap.totalValue, closeTo(5.0 * 39.45, 0.01));
      expect(evap.isLowStock, isFalse);
    });

    test('Detects low stock based on package threshold', () {
      final flour = InventoryItem(
        name: 'Cake Flour',
        category: 'Dry Goods',
        packageCount: 1.0,
        packageSize: 1000.0,
        measurementUnit: 'g',
        packageCost: 65.00,
        minStockAlert: 2.0,
      );

      expect(flour.isLowStock, isTrue);
    });

    test('Calculates cake COGS, labor, overhead, profit and suggested price', () {
      final evap = InventoryItem(
        id: 'inv-evap',
        name: 'Evaporated Milk',
        category: 'Dairy',
        packageCount: 5,
        packageSize: 360,
        measurementUnit: 'ml',
        packageCost: 39.45,
      );

      // Recipe requires 180ml
      final recipeItem = RecipeItem(
        recipeId: 'rec-1',
        ingredientName: 'Evaporated Milk',
        quantity: 180.0,
        unit: 'ml',
        inventoryItemId: evap.id,
      );

      final itemCost = RecipeItemCost(
        item: recipeItem,
        linkedInventoryItem: evap,
        unitCost: evap.costPerUnit,
        subtotalCost: 180.0 * evap.costPerUnit,
      );

      // 180 * (39.45 / 360) = 19.725 PHP
      expect(itemCost.subtotalCost, closeTo(19.725, 0.001));

      final product = Product(
        name: 'Chocolate Bento Cake',
        price: 350.0,
      );

      // Profile: 60 mins labor @ 100 PHP/hr, packaging 25 PHP, overhead 15 PHP, target margin 40%
      final profile = ProductCostingProfile(
        productId: product.id,
        prepTimeMinutes: 60,
        hourlyLaborRate: 100.0,
        packagingCost: 25.0,
        overheadFixedCost: 15.0,
        targetMarginPct: 40.0,
      );

      expect(profile.laborCost, equals(100.0));
      expect(profile.nonIngredientCost, equals(140.0));

      final breakdown = ProductCostBreakdown(
        product: product,
        itemCosts: [itemCost],
        profile: profile,
      );

      // Total Cost = 19.725 + 100 + 25 + 15 = 159.725 PHP
      expect(breakdown.totalCost, closeTo(159.725, 0.01));
      expect(breakdown.netProfit, closeTo(350.0 - 159.725, 0.01));
      // Margin % = (190.275 / 350) * 100 = 54.36%
      expect(breakdown.profitMarginPct, closeTo(54.364, 0.01));
      // Suggested price at 40% margin = 159.725 / (1 - 0.40) = 266.21 PHP
      expect(breakdown.suggestedPrice, closeTo(159.725 / 0.60, 0.01));
    });

    test('Parses fractional recipe inputs and formats them accurately', () {
      expect(parseFractionOrDecimal('1 1/2'), equals(1.5));
      expect(parseFractionOrDecimal('1/8'), equals(0.125));
      expect(parseFractionOrDecimal('1/4'), equals(0.25));
      expect(parseFractionOrDecimal('3/4'), equals(0.75));
      expect(parseFractionOrDecimal('1/3'), closeTo(0.3333, 0.001));
      expect(parseFractionOrDecimal('2 1/4'), equals(2.25));
      expect(parseFractionOrDecimal('2'), equals(2.0));
      expect(parseFractionOrDecimal('0.5'), equals(0.5));
      expect(parseFractionOrDecimal('1 ½'), equals(1.5));
      expect(parseFractionOrDecimal('⅛'), equals(0.125));

      expect(formatQuantity(1.5), equals('1 1/2'));
      expect(formatQuantity(0.125), equals('1/8'));
      expect(formatQuantity(0.25), equals('1/4'));
      expect(formatQuantity(0.75), equals('3/4'));
      expect(formatQuantity(0.3333), equals('1/3'));
      expect(formatQuantity(2.0), equals('2'));
      expect(formatQuantity(2.25), equals('2 1/4'));
    });

    test('Calculates exact COGS for fractional recipe measurements (1 1/2 cup, 1/8 cup, 1/4 tbsp)', () {
      // 1 can Evap Milk: 360ml @ 38.00 PHP -> unit cost = 38 / 360 PHP/ml
      final evap = InventoryItem(
        name: 'Evaporated Milk',
        brand: 'Nestle',
        category: 'Dairy',
        packageCount: 6,
        packageSize: 360,
        measurementUnit: 'ml',
        packageCost: 38.00,
      );

      // Recipe requires 1 1/2 cup (1.5 cups * 240 ml/cup = 360 ml)
      final cupsQty = parseFractionOrDecimal('1 1/2');
      final convertedMl1 = convertMeasurementUnit(cupsQty, 'cups', 'ml');
      expect(convertedMl1, equals(360.0));
      final cost1 = convertedMl1 * evap.costPerUnit;
      expect(cost1, closeTo(38.00, 0.001));

      // Recipe requires 1/8 cup (0.125 cups * 240 ml/cup = 30 ml)
      final eighthQty = parseFractionOrDecimal('1/8');
      final convertedMl2 = convertMeasurementUnit(eighthQty, 'cup', 'ml');
      expect(convertedMl2, equals(30.0));
      final cost2 = convertedMl2 * evap.costPerUnit;
      expect(cost2, closeTo(30.0 * (38.00 / 360.0), 0.001));

      // Recipe requires 1/4 tbsp vanilla (0.25 tbsp * 15 ml/tbsp = 3.75 ml)
      final quarterQty = parseFractionOrDecimal('1/4');
      final convertedMl3 = convertMeasurementUnit(quarterQty, 'tbsp', 'ml');
      expect(convertedMl3, equals(3.75));
    });
  });
}
