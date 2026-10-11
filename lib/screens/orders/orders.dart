import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/widgets.dart';

/// Filterable, searchable list of all orders.
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  OrderStatus? _selectedFilter;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged(OrderStatus? status) {
    setState(() {
      _selectedFilter = (_selectedFilter == status) ? null : status;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();
    final allOrders = orderService.orders;
    final isLoading = orderService.isLoading && allOrders.isEmpty;

    List<Order> filteredOrders =
        allOrders.where((o) => o.status != OrderStatus.cancelled).toList();

    // Apply status filter
    if (_selectedFilter != null) {
      filteredOrders =
          filteredOrders.where((o) => o.status == _selectedFilter).toList();
    }

    // Apply search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredOrders = filteredOrders.where((o) {
        final name = (o.customerName ?? '').toLowerCase();
        final id = o.id.toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name or order ID...',
                  border: InputBorder.none,
                  filled: false,
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text('Orders'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search orders',
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => context.read<OrderService>().loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 96),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return OrderCard(
                              order: order,
                              onTap: () => _navigateToDetail(order.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildChip(null, 'All', Icons.list),
          const SizedBox(width: 8),
          _buildChip(
            OrderStatus.pending,
            OrderStatus.pending.label,
            OrderStatus.pending.icon,
          ),
          const SizedBox(width: 8),
          _buildChip(
            OrderStatus.baking,
            OrderStatus.baking.label,
            OrderStatus.baking.icon,
          ),
          const SizedBox(width: 8),
          _buildChip(
            OrderStatus.ready,
            OrderStatus.ready.label,
            OrderStatus.ready.icon,
          ),
          const SizedBox(width: 8),
          _buildChip(
            OrderStatus.completed,
            OrderStatus.completed.label,
            OrderStatus.completed.icon,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(OrderStatus? status, String label, IconData icon) {
    final isSelected =
        (status == null && _selectedFilter == null) || _selectedFilter == status;
    final chipColor = status?.color ?? AppTheme.primaryColor;

    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => _onFilterChanged(status),
      selectedColor: chipColor.withValues(alpha: 0.15),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : AppTheme.dividerColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _selectedFilter != null;
    final hasSearch = _searchController.text.trim().isNotEmpty;

    String message;
    if (hasSearch) {
      message = 'No orders matching "${_searchController.text.trim()}"';
    } else if (hasFilter) {
      message = 'No ${_selectedFilter!.label.toLowerCase()} orders';
    } else {
      message = 'No orders yet';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (!hasSearch && !hasFilter)
              Text(
                'Create an order from the dashboard to get started.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textHint,
                    ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(String orderId) {
    Navigator.pushNamed(context, '/order-detail', arguments: orderId).then((_) {
      if (mounted) {
        context.read<OrderService>().loadOrders();
      }
    });
  }
}
