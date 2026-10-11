import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../repositories/payment_repository.dart';

/// Service that aggregates dashboard data for the home screen.
///
/// Fetches daily order summaries, recent orders, and today's revenue
/// in a single [loadDashboard] call so the dashboard can display
/// high-level metrics efficiently.
class DashboardService extends ChangeNotifier {
  final OrderRepository _orderRepo;
  final PaymentRepository _paymentRepo;

  Map<String, dynamic>? _dailySummary;
  List<Order> _recentOrders = [];
  double _todayRevenue = 0;
  bool _isLoading = false;

  DashboardService({
    required OrderRepository orderRepo,
    required PaymentRepository paymentRepo,
  }) : _orderRepo = orderRepo,
       _paymentRepo = paymentRepo;

  // ── Getters ──────────────────────────────────────────────────────

  Map<String, dynamic>? get dailySummary => _dailySummary;
  List<Order> get recentOrders => List.unmodifiable(_recentOrders);
  double get todayRevenue => _todayRevenue;
  bool get isLoading => _isLoading;

  // ── Convenience getters ──────────────────────────────────────────
  /// Convenience getters that pull values from the daily summary map
  /// returned by the repository. Falls back to 0 when data is unavailable.
  int get totalOrdersToday => (_dailySummary?['totalOrders'] as int?) ?? 0;

  int get pendingOrdersToday => (_dailySummary?['pendingCount'] as int?) ?? 0;

  int get bakingOrdersToday => (_dailySummary?['bakingCount'] as int?) ?? 0;

  int get readyOrdersToday => (_dailySummary?['readyCount'] as int?) ?? 0;

  int get completedOrdersToday =>
      (_dailySummary?['completedCount'] as int?) ?? 0;

  int get cancelledOrdersToday =>
      (_dailySummary?['cancelledCount'] as int?) ?? 0;

  // ── Loading ──────────────────────────────────────────────────────

  /// Loads all dashboard data in parallel for the current day.
  ///
  /// 1. Fetches the daily summary map (counts per status).
  /// 2. Fetches the 10 most recent orders for the activity feed.
  /// 3. Calculates today's revenue from completed-order payments.
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();

      // Run the three data-fetching operations in parallel.
      final results = await Future.wait([
        _orderRepo.getDailySummary(today),
        _orderRepo.getRecent(10),
        _paymentRepo.getRevenueForDate(today),
      ]);

      _dailySummary = results[0] as Map<String, dynamic>;
      _recentOrders = results[1] as List<Order>;
      _todayRevenue = results[2] as double;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
