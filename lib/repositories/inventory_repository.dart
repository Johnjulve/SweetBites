import '../models/inventory_item.dart';

/// Abstract interface for pantry inventory operations.
abstract class InventoryRepository {
  Future<List<InventoryItem>> getAll();
  Future<InventoryItem?> getById(String id);
  Future<void> insert(InventoryItem item);
  Future<void> update(InventoryItem item);
  Future<void> delete(String id);
  Future<void> updatePackageCount(String id, double newCount);
}
