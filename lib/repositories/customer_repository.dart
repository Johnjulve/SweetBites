import '../models/customer.dart';

/// Abstract interface for customer data operations.
abstract class CustomerRepository {
  Future<List<Customer>> getAll();
  Future<Customer?> getById(String id);
  Future<List<Customer>> search(String query);
  Future<void> insert(Customer customer);
  Future<void> update(Customer customer);
  Future<void> delete(String id);
  Future<List<Map<String, dynamic>>> getCustomersWithOrderCount();
}
