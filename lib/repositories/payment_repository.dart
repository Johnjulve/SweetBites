import '../models/payment.dart';

/// Abstract interface for payment data operations.
abstract class PaymentRepository {
  Future<List<Payment>> getByOrderId(String orderId);
  Future<void> insert(Payment payment);
  Future<void> delete(String id);
  Future<double> getTotalPaidForOrder(String orderId);
  Future<double> getRevenueForDate(DateTime date);
  Future<void> voidPaymentsForOrder(String orderId);
  Future<void> voidPayment(String paymentId);
}
