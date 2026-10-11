import '../core/constants.dart';
import '../core/helpers.dart';
import 'order_item.dart';

/// Represents a bakery order.
class Order {
  final String id;
  final String customerId;
  final String? customerName; // Denormalized for display convenience
  final double totalAmount;
  final OrderStatus status;
  final DateTime pickupDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    String? id,
    required this.customerId,
    this.customerName,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    required this.pickupDate,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items = const [],
  })  : id = id ?? generateId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'total_amount': totalAmount,
      'status': status.name,
      'pickup_date': toDbString(pickupDate),
      'notes': notes,
      'created_at': toDbString(createdAt),
      'updated_at': toDbString(updatedAt),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? items}) {
    return Order(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      customerName: map['customer_name'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: OrderStatus.fromString(map['status'] as String),
      pickupDate: fromDbString(map['pickup_date'] as String),
      notes: map['notes'] as String? ?? '',
      createdAt: fromDbString(map['created_at'] as String),
      updatedAt: fromDbString(map['updated_at'] as String),
      items: items ?? [],
    );
  }

  Order copyWith({
    String? customerId,
    String? customerName,
    double? totalAmount,
    OrderStatus? status,
    DateTime? pickupDate,
    String? notes,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      pickupDate: pickupDate ?? this.pickupDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'Order(id: $id, customer: $customerId, total: $totalAmount, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
