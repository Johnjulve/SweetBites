import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../services/costing_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/inventory_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/widgets.dart';

/// The main home dashboard screen showing at-a-glance bakery stats
/// and recent orders.
class DashboardScreen extends StatefulWidget {
  /// Optional callback to switch to a different bottom-nav tab index.
  final void Function(int index)? onSwitchTab;

  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _ordersToday = 0;
  double _revenueToday = 0;
  int _pendingCount = 0;
  int _readyCount = 0;
  List<Order> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final dashboardService = context.read<DashboardService>();
      await dashboardService.loadDashboard();

      if (!mounted) return;
      setState(() {
        _ordersToday = dashboardService.totalOrdersToday;
        _revenueToday = dashboardService.todayRevenue;
        _pendingCount = dashboardService.pendingOrdersToday;
        _readyCount = dashboardService.readyOrdersToday;
        _recentOrders = dashboardService.recentOrders.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load dashboard: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('SweetBites'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryColor.withValues(alpha: 0.18)
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: const Text(
                'v${AppConstants.appVersion}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        scrolledUnderElevation: 0,
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, _) {
              final isDark = themeService.isDarkMode;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => themeService.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/settings',
              ).then((_) => _loadDashboard());
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _buildSummaryGrid(),
                    const SizedBox(height: 8),
                    _buildRecentOrdersHeader(),
                    if (_recentOrders.isEmpty) _buildEmptyState(),
                    ..._recentOrders.map(
                      (order) => OrderCard(
                        order: order,
                        onTap: () => _navigateToOrderDetail(order.id),
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_new_order_fab',
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/create-order',
          ).then((_) => _loadDashboard());
        },
        tooltip: 'New Order',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final inventoryService = context.watch<InventoryService>();
    final costingService = context.watch<CostingService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          SummaryCard(
            title: 'Orders Today',
            value: '$_ordersToday',
            icon: Icons.receipt_long,
            iconColor: const Color(0xFF3B82F6),
            iconBackgroundColor: const Color(0xFFDBEAFE),
          ),
          SummaryCard(
            title: 'Revenue Today',
            value: formatCurrency(_revenueToday),
            icon: Icons.trending_up,
            iconColor: const Color(0xFF10B981),
            iconBackgroundColor: const Color(0xFFD1FAE5),
          ),
          SummaryCard(
            title: 'Pending',
            value: '$_pendingCount',
            icon: Icons.schedule,
            iconColor: const Color(0xFFF59E0B),
            iconBackgroundColor: const Color(0xFFFEF3C7),
          ),
          SummaryCard(
            title: 'Ready for Pickup',
            value: '$_readyCount',
            icon: Icons.check_circle_outline,
            iconColor: AppTheme.primaryColor,
            iconBackgroundColor: AppTheme.primaryLight,
          ),
          SummaryCard(
            title: 'Inventory Value',
            value: formatCurrency(inventoryService.totalInventoryValue),
            icon: Icons.kitchen_outlined,
            iconColor: const Color(0xFF8B5CF6),
            iconBackgroundColor: const Color(0xFFEDE9FE),
          ),
          SummaryCard(
            title: 'Avg Cake Margin',
            value: '${costingService.averageProfitMarginPct.toStringAsFixed(1)}%',
            icon: Icons.pie_chart_outline,
            iconColor: AppTheme.primaryColor,
            iconBackgroundColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onSwitchTab?.call(1);
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.cake_outlined,
            size: 64,
            color: AppTheme.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet today',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first order!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetail(String orderId) {
    Navigator.pushNamed(
      context,
      '/order-detail',
      arguments: orderId,
    ).then((_) => _loadDashboard());
  }
}
