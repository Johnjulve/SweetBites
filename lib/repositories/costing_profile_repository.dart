import '../models/product_costing_profile.dart';

/// Abstract interface for product costing profile data operations.
abstract class CostingProfileRepository {
  Future<ProductCostingProfile?> getByProductId(String productId);
  Future<Map<String, ProductCostingProfile>> getAllProfiles();
  Future<void> save(ProductCostingProfile profile);
  Future<void> delete(String productId);
}
