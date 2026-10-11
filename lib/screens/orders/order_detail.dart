import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../models/recipe.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';

/// Full order detail view with status management, items, recipes,
/// payments, and receipt access.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Order? _order;
  Customer? _customer;
  PaymentSummary? _paymentSummary;
  Map<String, Recipe?> _recipes = {}; // productId -> recipe
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final orderService = context.read<OrderService>();
      final paymentService = context.read<PaymentService>();
      final productService = context.read<ProductService>();

      final order = await orderService.getOrderById(widget.orderId);
      if (order == null || !mounted) return;

      final customer = await orderService.getCustomerForOrder(order.customerId);
      final paymentSummary = await paymentService.getPaymentSummary(
        order.id,
        order.totalAmount,
      );

      // Load recipes for each product in the order
      final recipes = <String, Recipe?>{};
      for (final item in order.items) {
        final recipe = await productService.getRecipe(item.productId);
        recipes[item.productId] = recipe;
      }

      var currentOrder = order;
      final isPaymentComplete = paymentSummary.balance <= 0.01;
      final itemsWithRecipes = currentOrder.items
          .where((item) => recipes[item.productId] != null)
          .toList();
      final allRecipesChecked = itemsWithRecipes.isEmpty ||
          itemsWithRecipes.every((item) {
            final recipe = recipes[item.productId];
            return recipe == null ||
                recipe.items.isEmpty ||
                recipe.items.every((i) => i.isChecked);
          });

      // Auto-reconcile: If order was marked completed but prerequisites are incomplete, revert to ready
      if (currentOrder.status == OrderStatus.completed &&
          (!isPaymentComplete || !allRecipesChecked)) {
        await orderService.updateOrderStatus(currentOrder.id, OrderStatus.ready);
        final revertedOrder = await orderService.getOrderById(currentOrder.id);
        if (revertedOrder != null) {
          currentOrder = revertedOrder;
        }
      }

      if (!mounted) return;
      setState(() {
        _order = currentOrder;
        _customer = customer;
        _paymentSummary = paymentSummary;
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load order: $e')),
      );
    }
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    if (_order == null) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final orderService = context.read<OrderService>();
      await orderService.updateOrderStatus(_order!.id, newStatus);
      await _loadOrderDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _recordPayment() async {
    if (_order == null || _paymentSummary == null) return;

    final paymentService = context.read<PaymentService>();

    final result = await showDialog<Payment>(
      context: context,
      builder: (context) => PaymentDialog(
        orderId: _order!.id,
        balance: _paymentSummary!.balance,
      ),
    );

    if (result != null) {
      try {
        await paymentService.recordPayment(
          orderId: result.orderId,
          amount: result.amountPaid,
          method: result.paymentMethod,
          notes: result.notes,
        );
        await _loadOrderDetails();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    }
  }

  Future<void> _voidSinglePayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Payment?'),
        content: Text(
          'Are you sure you want to void this ${payment.paymentMethod.toUpperCase()} payment of ${formatCurrency(payment.amountPaid)}? This action cannot be undone and the amount will no longer count towards the order\'s total paid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Void Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final paymentService = context.read<PaymentService>();
      await paymentService.voidPayment(payment.id);
      await _loadOrderDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment voided successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to void payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order != null ? shortOrderId(_order!.id) : 'Order',
        ),
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'View Receipt',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/receipt',
                  arguments: _order!.id,
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildNotFound()
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrderCustomerInfoSection(
                          order: _order!,
                          customer: _customer,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusSection(),
                        const SizedBox(height: 16),
                        OrderItemsSection(order: _order!),
                        const SizedBox(height: 16),
                        _buildRecipeSection(),
                        const SizedBox(height: 16),
                        _buildPaymentSection(),
                        if (_order!.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildNotesSection(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text(
            'Order not found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }


  // ── Status ──────────────────────────────────────────────────────
  Widget _buildStatusSection() {
    final bool isPaymentComplete =
        _paymentSummary != null && _paymentSummary!.balance <= 0.01;

    final itemsWithRecipes = _order!.items
        .where((item) => _recipes[item.productId] != null)
        .toList();

    final bool allRecipesChecked = itemsWithRecipes.isEmpty ||
        itemsWithRecipes.every((item) {
          final recipe = _recipes[item.productId];
          return recipe == null ||
              recipe.items.isEmpty ||
              recipe.items.every((i) => i.isChecked);
        });

    final bool canComplete = isPaymentComplete && allRecipesChecked;

    String? completeDisabledReason;
    if (!canComplete) {
      if (!isPaymentComplete && !allRecipesChecked) {
        completeDisabledReason =
            'All recipe items must be checked and payment fully settled before completing order.';
      } else if (!isPaymentComplete) {
        final balanceStr =
            formatCurrency(_paymentSummary?.balance ?? _order!.totalAmount);
        completeDisabledReason =
            'Payment must be fully settled before completing order (Balance: $balanceStr).';
      } else if (!allRecipesChecked) {
        completeDisabledReason =
            'All recipe checklist ingredients must be checked before completing order.';
      }
    }

    return OrderStatusSection(
      status: _order!.status,
      isUpdating: _isUpdatingStatus,
      canComplete: canComplete,
      completeDisabledReason: completeDisabledReason,
      onStatusSelected: (target, label) =>
          _confirmStatusChange(target, label, canComplete: canComplete, disabledReason: completeDisabledReason),
    );
  }

  Future<void> _confirmStatusChange(
    OrderStatus target,
    String label, {
    bool canComplete = true,
    String? disabledReason,
  }) async {
    if (target == OrderStatus.completed && !canComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(disabledReason ?? 'Cannot complete order yet.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (target == OrderStatus.cancelled) {
      final hasPayments = _paymentSummary != null && _paymentSummary!.payments.isNotEmpty;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(hasPayments ? 'Cancel Order & Void Payments?' : 'Cancel Order?'),
          content: Text(
            hasPayments
                ? 'This order has recorded payments. If you cancel this order, all associated payments will be permanently voided and crossed out. This action cannot be undone.'
                : 'This action cannot be undone. The order will be permanently marked as cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: Text(hasPayments ? 'Void & Cancel Order' : 'Cancel Order'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;

      if (hasPayments) {
        try {
          final paymentService = context.read<PaymentService>();
          await paymentService.voidPaymentsForOrder(_order!.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to void payments: $e')),
            );
          }
          return;
        }
      }
    }
    _updateStatus(target);
  }


  // ── Recipes ─────────────────────────────────────────────────────
  Widget _buildRecipeSection() {
    final itemsWithRecipes = _order!.items
        .where((item) => _recipes[item.productId] != null)
        .toList();

    if (itemsWithRecipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          ...itemsWithRecipes.map((item) {
            final recipe = _recipes[item.productId]!;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: RecipeChecklist(
                productName: item.productName ?? 'Product',
                recipe: recipe,
                quantity: item.quantity,
                onItemToggled: (itemId, checked) async {
                  await context
                      .read<ProductService>()
                      .updateRecipeItemChecked(itemId, checked);
                  if (!mounted) return;
                  final updatedItems = recipe.items.map((i) {
                    if (i.id == itemId) return i.copyWith(isChecked: checked);
                    return i;
                  }).toList();
                  setState(() {
                    _recipes[item.productId] =
                        recipe.copyWith(items: updatedItems);
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Payment ─────────────────────────────────────────────────────
  Widget _buildPaymentSection() {
    final summary = _paymentSummary;
    if (summary == null) return const SizedBox.shrink();

    return OrderPaymentSection(
      order: _order!,
      paymentSummary: summary,
      onRecordPayment: _recordPayment,
      onVoidPayment: _voidSinglePayment,
    );
  }

  // ── Notes ───────────────────────────────────────────────────────
  Widget _buildNotesSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _order!.notes,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card wrapper ────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );
  }
}
