import 'package:flutter/material.dart';

/// App-wide constants for the SweetBites bakery application.

class AppConstants {
  AppConstants._();

  // App & Version
  static const String appName = 'SweetBites';
  static const String appVersion = '1.0.0';
  static const String defaultGithubRepo = 'Johnjulve/SweetBites';

  // Bakery defaults
  static const String defaultBakeryName = 'SweetBites Bakery';
  static const String defaultBakeryAddress = '';
  static const String defaultBakeryPhone = '';

  // Currency
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';

  // Database
  static const String databaseName = 'sweetbites.db';
  static const int databaseVersion = 4;

  // Table names
  static const String tableCustomers = 'customers';
  static const String tableProducts = 'products';
  static const String tableRecipes = 'recipes';
  static const String tableRecipeItems = 'recipe_items';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tablePayments = 'payments';
  static const String tableInventoryItems = 'inventory_items';
  static const String tableProductCostingProfiles = 'product_costing_profiles';

  // SharedPreferences keys
  static const String prefBakeryName = 'bakery_name';
  static const String prefBakeryAddress = 'bakery_address';
  static const String prefBakeryPhone = 'bakery_phone';
  static const String prefGithubRepo = 'github_repo';
  static const String prefDarkMode = 'dark_mode';
}

/// Order status values with display properties.
enum OrderStatus {
  pending('Pending', Color(0xFFF59E0B), Color(0xFFFEF3C7), Icons.schedule),
  baking('Baking', Color(0xFFF97316), Color(0xFFFFF7ED), Icons.local_fire_department),
  ready('Ready', Color(0xFF10B981), Color(0xFFECFDF5), Icons.check_circle_outline),
  completed('Completed', Color(0xFF6366F1), Color(0xFFEEF2FF), Icons.done_all),
  cancelled('Cancelled', Color(0xFFEF4444), Color(0xFFFEF2F2), Icons.cancel_outlined);

  const OrderStatus(this.label, this.color, this.backgroundColor, this.icon);

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Payment status values with display properties.
enum PaymentStatus {
  unpaid('Unpaid', Color(0xFFEF4444), Color(0xFFFEF2F2), Icons.money_off),
  partial('Partial', Color(0xFFF59E0B), Color(0xFFFEF3C7), Icons.payments_outlined),
  paid('Paid', Color(0xFF10B981), Color(0xFFECFDF5), Icons.paid);

  const PaymentStatus(this.label, this.color, this.backgroundColor, this.icon);

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

/// Allowed order status transitions.
class OrderStatusTransitions {
  OrderStatusTransitions._();

  static const Map<OrderStatus, List<OrderStatus>> allowed = {
    OrderStatus.pending: [OrderStatus.baking, OrderStatus.cancelled],
    OrderStatus.baking: [OrderStatus.ready, OrderStatus.cancelled],
    OrderStatus.ready: [OrderStatus.completed, OrderStatus.cancelled],
    OrderStatus.completed: [OrderStatus.ready],
    OrderStatus.cancelled: [],
  };

  static bool canTransition(OrderStatus from, OrderStatus to) {
    return allowed[from]?.contains(to) ?? false;
  }

  static List<OrderStatus> getNextStatuses(OrderStatus current) {
    return allowed[current] ?? [];
  }
}
