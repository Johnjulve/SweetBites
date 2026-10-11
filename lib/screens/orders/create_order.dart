import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';

/// Order creation screen with inline sections: customer selection,
/// product picking, pickup date, notes, and a place-order button.
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  Customer? _selectedCustomer;
  final Map<String, _CartEntry> _cart = {}; // productId -> entry
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  List<Product> _products = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final productService = context.read<ProductService>();
      final products = await productService.getActiveProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    }
  }

  double get _totalAmount {
    return _cart.values.fold(0.0, (sum, entry) => sum + entry.subtotal);
  }

  bool get _canPlaceOrder {
    return _selectedCustomer != null && _cart.isNotEmpty && !_isSubmitting;
  }

  void _updateQuantity(Product product, int delta) {
    setState(() {
      final existing = _cart[product.id];
      if (existing != null) {
        final newQty = existing.quantity + delta;
        if (newQty <= 0) {
          _cart.remove(product.id);
        } else {
          _cart[product.id] = _CartEntry(product: product, quantity: newQty);
        }
      } else if (delta > 0) {
        _cart[product.id] = _CartEntry(product: product, quantity: delta);
      }
    });
  }

  int _getQuantity(String productId) {
    return _cart[productId]?.quantity ?? 0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select Pickup Date',
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_pickupDate),
        helpText: 'Select Pickup Time',
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _pickupDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder) return;

    setState(() => _isSubmitting = true);
    try {
      final orderService = context.read<OrderService>();

      final items =
          _cart.values.map((entry) {
            return OrderItem(
              orderId: '', // Will be set by service
              productId: entry.product.id,
              productName: entry.product.name,
              quantity: entry.quantity,
              unitPrice: entry.product.price,
            );
          }).toList();

      await orderService.createOrder(
        customerId: _selectedCustomer!.id,
        items: items,
        pickupDate: _pickupDate,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! 🎉'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Step 1: Customer ──
                          _buildSectionHeader(
                            icon: Icons.person_outline,
                            title: 'Customer',
                            step: '1',
                          ),
                          const SizedBox(height: 8),
                          CustomerSelector(
                            selectedCustomer: _selectedCustomer,
                            onCustomerSelected: (customer) {
                              setState(() => _selectedCustomer = customer);
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Step 2: Products ──
                          _buildSectionHeader(
                            icon: Icons.cake_outlined,
                            title: 'Products',
                            step: '2',
                          ),
                          const SizedBox(height: 8),
                          if (_products.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No active products available',
                                  style: TextStyle(color: AppTheme.textHint),
                                ),
                              ),
                            )
                          else
                            ..._products.map(
                              (product) => ProductTile(
                                product: product,
                                quantity: _getQuantity(product.id),
                                onAdd: () => _updateQuantity(product, 1),
                                onRemove: () => _updateQuantity(product, -1),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // ── Step 3: Pickup Date ──
                          _buildSectionHeader(
                            icon: Icons.calendar_today_outlined,
                            title: 'Pickup Date',
                            step: '3',
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final theme = Theme.of(context);
                              final isDark = theme.brightness == Brightness.dark;
                              return InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF241F1B)
                                        : AppTheme.surfaceDim,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF382F28)
                                          : const Color(0xFFE8DFD6),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        formatDateTime(_pickupDate),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${formatRelativeDate(_pickupDate)})',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFFB5A496)
                                              : AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: isDark
                                            ? const Color(0xFF7A6B5D)
                                            : AppTheme.textHint,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Step 4: Notes ──
                          _buildSectionHeader(
                            icon: Icons.notes_outlined,
                            title: 'Notes (Optional)',
                            step: '4',
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Special instructions, messages, etc.',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom Bar ──
                  _buildBottomBar(),
                ],
              ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String step,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFFD49B6A) : AppTheme.secondaryColor,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241F1B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF382F28)
                : const Color(0xFFE8DFD6).withValues(alpha: 0.8),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cart.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_cart.values.fold(0, (sum, e) => sum + e.quantity)} item(s)',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFB5A496)
                            : AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      formatCurrency(_totalAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canPlaceOrder ? _placeOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF382F28)
                      : const Color(0xFFE8DFD6),
                  disabledForegroundColor: isDark
                      ? const Color(0xFF7A6B5D)
                      : const Color(0xFFB5A99A),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _cart.isEmpty
                              ? 'Place Order'
                              : 'Place Order  •  ${formatCurrency(_totalAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal cart entry to track selected product + quantity.
class _CartEntry {
  final Product product;
  final int quantity;

  _CartEntry({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}
