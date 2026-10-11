import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../repositories/payment_repository.dart';

/// Service that manages payment operations.
///
/// Provides methods to record payments, retrieve payment summaries for
/// orders, and delete payments. Notifies listeners so the UI can react
/// to payment state changes.
class PaymentService extends ChangeNotifier {
  final PaymentRepository _paymentRepo;

  PaymentService({required PaymentRepository paymentRepo})
      : _paymentRepo = paymentRepo;

  /// Builds a [PaymentSummary] for a given order.
  ///
  /// Fetches all payments for [orderId], then uses the factory
  /// [PaymentSummary.calculate] with the [orderTotal] to derive
  /// totalPaid, balance, and status.
  Future<PaymentSummary> getPaymentSummary(
      String orderId, double orderTotal) async {
    final payments = await _paymentRepo.getByOrderId(orderId);
    return PaymentSummary.calculate(
      orderTotal: orderTotal,
      payments: payments,
    );
  }

  /// Records a new payment against an order and notifies listeners.
  ///
  /// [method] defaults to `'cash'` if not supplied.
  Future<Payment> recordPayment({
    required String orderId,
    required double amount,
    String method = 'cash',
    String notes = '',
  }) async {
    final payment = Payment(
      orderId: orderId,
      amountPaid: amount,
      paymentMethod: method,
      notes: notes,
    );

    await _paymentRepo.insert(payment);
    notifyListeners();

    return payment;
  }

  /// Deletes a payment by [id] and notifies listeners.
  Future<void> deletePayment(String id) async {
    await _paymentRepo.delete(id);
    notifyListeners();
  }

  /// Voids all payments for a given order and notifies listeners.
  Future<void> voidPaymentsForOrder(String orderId) async {
    await _paymentRepo.voidPaymentsForOrder(orderId);
    notifyListeners();
  }

  /// Voids a single payment and notifies listeners.
  Future<void> voidPayment(String paymentId) async {
    await _paymentRepo.voidPayment(paymentId);
    notifyListeners();
  }
}
