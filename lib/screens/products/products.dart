import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/costing_service.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';

/// Product catalog management with inline editing and recipe management.
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  bool _isLoading = true;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productService = context.read<ProductService>();
      final products = await productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    }
  }

  void _showProductForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => ProductFormSheet(
            product: product,
            onSaved: () {
              Navigator.pop(ctx);
              _loadProducts();
            },
          ),
    );
  }

  void _showRecipeEditor(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => RecipeEditorSheet(
            product: product,
            onSaved: () {
              Navigator.pop(ctx);
              _loadProducts();
              if (mounted) {
                context.read<CostingService>().loadCostings();
              }
            },
          ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final productService = context.read<ProductService>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await productService.deleteProduct(product.id);
        await _loadProducts();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => _showProductForm(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_products[index]);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cake_outlined,
            size: 64,
            color: AppTheme.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first product.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: product.isActive
                ? (isDark
                    ? const Color(0xFFE8734A).withValues(alpha: 0.18)
                    : AppTheme.primaryLight)
                : (isDark
                    ? const Color(0xFF2E2722)
                    : AppTheme.surfaceDim),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.cake,
            color: product.isActive ? AppTheme.primaryColor : AppTheme.textHint,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: product.isActive
                      ? theme.colorScheme.onSurface
                      : (isDark ? const Color(0xFF7A6B5D) : AppTheme.textHint),
                ),
              ),
            ),
            if (!product.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2722) : AppTheme.surfaceDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF7A6B5D) : AppTheme.textHint,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            formatCurrency(product.price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.description.isNotEmpty) ...[
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFB5A496)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showProductForm(product: product),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRecipeEditor(product),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: const Text('Recipe'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteProduct(product),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text('Delete Product', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
