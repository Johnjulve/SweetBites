import '../core/helpers.dart';

/// A single line item in an order.
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String? productName; // Denormalized for display
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    String? id,
    required this.orderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    double? subtotal,
  })  : id = id ?? generateId(),
        subtotal = subtotal ?? (unitPrice * quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  OrderItem copyWith({
    int? quantity,
    double? unitPrice,
  }) {
    final newQty = quantity ?? this.quantity;
    final newPrice = unitPrice ?? this.unitPrice;
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      productName: productName,
      quantity: newQty,
      unitPrice: newPrice,
      subtotal: newQty * newPrice,
    );
  }

  @override
  String toString() =>
      'OrderItem(product: $productId, qty: $quantity, subtotal: $subtotal)';
}
