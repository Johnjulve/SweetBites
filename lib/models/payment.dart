import '../core/helpers.dart';

/// A payment transaction recorded against an order.
/// Multiple payments can be made per order (e.g. deposit + final payment).
class Payment {
  final String id;
  final String orderId;
  final double amountPaid;
  final String paymentMethod; // cash, gcash, bank_transfer, etc.
  final String notes;
  final DateTime paidAt;
  final bool isVoided;

  Payment({
    String? id,
    required this.orderId,
    required this.amountPaid,
    this.paymentMethod = 'cash',
    this.notes = '',
    DateTime? paidAt,
    this.isVoided = false,
  })  : id = id ?? generateId(),
        paidAt = paidAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'notes': notes,
      'paid_at': toDbString(paidAt),
      'is_voided': isVoided ? 1 : 0,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      amountPaid: (map['amount_paid'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      notes: map['notes'] as String? ?? '',
      paidAt: fromDbString(map['paid_at'] as String),
      isVoided: (map['is_voided'] as int? ?? 0) == 1,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, order: $orderId, amount: $amountPaid, method: $paymentMethod, isVoided: $isVoided)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Summary of payments against an order, computed from payment records.
class PaymentSummary {
  final double totalAmount;
  final double totalPaid;
  final double balance;
  final String status; // 'paid', 'partial', 'unpaid'
  final List<Payment> payments;

  PaymentSummary({
    required this.totalAmount,
    required this.totalPaid,
    required this.balance,
    required this.status,
    this.payments = const [],
  });

  factory PaymentSummary.calculate({
    required double orderTotal,
    required List<Payment> payments,
  }) {
    final totalPaid = payments
        .where((p) => !p.isVoided)
        .fold<double>(0, (sum, p) => sum + p.amountPaid);
    final balance = orderTotal - totalPaid;
    String status;
    if (totalPaid <= 0) {
      status = 'unpaid';
    } else if (balance <= 0.01) {
      // small tolerance for floating point
      status = 'paid';
    } else {
      status = 'partial';
    }
    return PaymentSummary(
      totalAmount: orderTotal,
      totalPaid: totalPaid,
      balance: balance < 0 ? 0 : balance,
      status: status,
      payments: payments,
    );
  }
}
