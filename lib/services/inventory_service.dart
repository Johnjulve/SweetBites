import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Service managing pantry items, physical counts, restock, and low-stock alerts.
class InventoryService extends ChangeNotifier {
  final InventoryRepository _repo;

  List<InventoryItem> _items = [];
  bool _isLoading = false;

  InventoryService({required InventoryRepository repository})
      : _repo = repository;

  List<InventoryItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  /// Total valuation of all physical inventory currently in stock.
  double get totalInventoryValue =>
      _items.fold(0.0, (sum, item) => sum + item.totalValue);

  /// Items currently below or at their minimum stock alert threshold.
  List<InventoryItem> get lowStockItems =>
      _items.where((item) => item.isLowStock).toList();

  /// Set of distinct categories present in inventory.
  List<String> get categories {
    final set = _items.map((e) => e.category).toSet().toList();
    set.sort();
    return set;
  }

  /// Loads all inventory items from repository.
  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repo.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new inventory item.
  Future<void> addItem(InventoryItem item) async {
    await _repo.insert(item);
    await loadInventory();
  }

  /// Update existing inventory item (name, brand, package cost, etc.).
  Future<void> updateItem(InventoryItem item) async {
    await _repo.update(item);
    await loadInventory();
  }

  /// Delete inventory item.
  Future<void> deleteItem(String id) async {
    await _repo.delete(id);
    await loadInventory();
  }

  /// Quickly adjust package count (e.g. +1 or -1 package).
  Future<void> adjustPackageCount(String id, double delta) async {
    final item = _items.firstWhere((i) => i.id == id, orElse: () => throw Exception('Item not found'));
    final newCount = (item.packageCount + delta).clamp(0.0, 999999.0);
    await _repo.updatePackageCount(id, newCount);
    await loadInventory();
  }

  /// Directly set package count.
  Future<void> setPackageCount(String id, double newCount) async {
    final clamped = newCount.clamp(0.0, 999999.0);
    await _repo.updatePackageCount(id, clamped);
    await loadInventory();
  }
}
