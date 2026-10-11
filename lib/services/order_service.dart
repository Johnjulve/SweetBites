import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/helpers.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/customer_repository.dart';
import '../repositories/order_repository.dart';

/// Service that manages order state and business logic.
///
/// Acts as a ChangeNotifier so UI widgets can rebuild when order data changes.
/// Wraps the underlying repositories and enforces business rules such as
/// valid status transitions before persisting changes.
class OrderService extends ChangeNotifier {
  final OrderRepository _orderRepo;
  final CustomerRepository _customerRepo;

  List<Order> _orders = [];
  bool _isLoading = false;

  OrderService({
    required OrderRepository orderRepo,
    required CustomerRepository customerRepo,
  })  : _orderRepo = orderRepo,
        _customerRepo = customerRepo;

  // ── Getters ──────────────────────────────────────────────────────

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  // ── Data Loading ─────────────────────────────────────────────────

  /// Loads all orders from the repository and notifies listeners.
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _orderRepo.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a list of all orders directly from the repository.
  Future<List<Order>> getAllOrders() async {
    return _orderRepo.getAll();
  }

  /// Loads orders filtered by a specific [status].
  Future<void> loadOrdersByStatus(OrderStatus status) async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _orderRepo.getByStatus(status);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads orders filtered by a specific [date] (matches the day only).
  Future<void> loadOrdersByDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _orderRepo.getByDate(date);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a single order by its [id], or null if not found.
  Future<Order?> getOrderById(String id) async {
    return _orderRepo.getById(id);
  }

  /// Returns the customer details for a given [customerId].
  Future<Customer?> getCustomerForOrder(String customerId) async {
    return _customerRepo.getById(customerId);
  }

  // ── Mutations ────────────────────────────────────────────────────

  /// Creates a new order and persists it.
  ///
  /// Calculates the total from the provided [items] list, looks up the
  /// customer name for denormalised display, and inserts the order via the
  /// repository. Returns the newly created [Order].
  Future<Order> createOrder({
    required String customerId,
    required List<OrderItem> items,
    required DateTime pickupDate,
    String notes = '',
  }) async {
    // Calculate order total from item subtotals.
    final double total =
        items.fold<double>(0, (sum, item) => sum + item.subtotal);

    // Resolve customer name for the denormalised field on Order.
    final customer = await _customerRepo.getById(customerId);
    final customerName = customer?.name;

    final orderId = generateId();

    // Re-create items with the order's ID assigned.
    final orderItems = items
        .map((item) => OrderItem(
              orderId: orderId,
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ))
        .toList();

    final order = Order(
      id: orderId,
      customerId: customerId,
      customerName: customerName,
      totalAmount: total,
      status: OrderStatus.pending,
      pickupDate: pickupDate,
      notes: notes,
      items: orderItems,
    );

    await _orderRepo.insert(order);

    // Reload orders so the cache is up-to-date.
    await loadOrders();

    return order;
  }

  /// Updates the status of an order after validating the transition.
  ///
  /// Returns `true` if the update succeeded, `false` if the transition
  /// from the current status to [newStatus] is not allowed.
  Future<bool> updateOrderStatus(
      String orderId, OrderStatus newStatus) async {
    final order = await _orderRepo.getById(orderId);
    if (order == null) return false;

    if (!OrderStatusTransitions.canTransition(order.status, newStatus)) {
      return false;
    }

    await _orderRepo.updateStatus(orderId, newStatus);

    // Refresh local cache.
    await loadOrders();
    return true;
  }

  /// Deletes an order by [id] and refreshes the cache.
  Future<void> deleteOrder(String id) async {
    await _orderRepo.delete(id);
    await loadOrders();
  }
}
