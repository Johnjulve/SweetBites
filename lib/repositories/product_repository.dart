import '../models/product.dart';

/// Abstract interface for product data operations.
abstract class ProductRepository {
  Future<List<Product>> getAll();
  Future<List<Product>> getActive();
  Future<Product?> getById(String id);
  Future<void> insert(Product product);
  Future<void> update(Product product);
  Future<void> delete(String id);
}
