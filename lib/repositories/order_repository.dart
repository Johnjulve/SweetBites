import '../core/constants.dart';
import '../models/order.dart';

/// Abstract interface for order data operations.
abstract class OrderRepository {
  Future<List<Order>> getAll();
  Future<Order?> getById(String id);
  Future<List<Order>> getByStatus(OrderStatus status);
  Future<List<Order>> getByDate(DateTime date);
  Future<List<Order>> getRecent(int limit);
  Future<void> insert(Order order);
  Future<void> updateStatus(String id, OrderStatus status);
  Future<void> delete(String id);
  Future<Map<String, dynamic>> getDailySummary(DateTime date);
}
