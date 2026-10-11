import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/inventory_item.dart';
import '../../models/product_cost_breakdown.dart';
import '../../services/costing_service.dart';
import '../../services/inventory_service.dart';
import 'costing_editor_sheet.dart';
import 'inventory_item_sheet.dart';

/// Unified screen combining Pantry Inventory management and Dynamic Cake Costing Analytics.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openItemSheet({InventoryItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InventoryItemSheet(
        item: item,
        onSaved: (saved) async {
          final service = context.read<InventoryService>();
          if (item == null) {
            await service.addItem(saved);
          } else {
            await service.updateItem(saved);
          }
          // Refresh costing calculations since ingredient purchase cost might have changed
          if (mounted) {
            context.read<CostingService>().loadCostings();
          }
        },
      ),
    );
  }

  void _openCostingSheet(ProductCostBreakdown breakdown) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CostingEditorSheet(
        breakdown: breakdown,
        onSaved: (profile) async {
          await context.read<CostingService>().saveProfile(profile);
        },
      ),
    );
  }

  Future<void> _confirmDelete(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text('Are you sure you want to delete "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<InventoryService>().deleteItem(item.id);
      if (mounted) {
        context.read<CostingService>().loadCostings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final costingService = context.watch<CostingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Costing'),
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.kitchen_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Pantry & Stock'),
                  if (inventoryService.lowStockItems.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${inventoryService.lowStockItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Costing & Margins'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPantryTab(inventoryService),
          _buildCostingTab(costingService),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'inventory_add_item_fab',
        onPressed: () => _openItemSheet(),
        tooltip: 'Add Pantry Item',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB 1: PANTRY & STOCKS (Physical Inventory)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPantryTab(InventoryService service) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (service.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allItems = service.items;
    final categories = ['All', ...service.categories];

    final filtered = allItems.where((item) {
      final matchesCat = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => service.loadInventory(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // Total Valuation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.85),
                  AppTheme.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Inventory Valuation',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(service.totalInventoryValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${service.items.length} Items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Box
          TextField(
            decoration: InputDecoration(
              hintText: 'Search pantry ingredients, brands...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),

          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: isDark
                        ? const Color(0xFFE8734A).withValues(alpha: 0.22)
                        : AppTheme.primaryLight,
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No pantry items found',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((item) => _buildPantryItemCard(item, service)),
        ],
      ),
    );
  }

  Widget _buildPantryItemCard(InventoryItem item, InventoryService service) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final countLabel = item.packageCount.truncateToDouble() == item.packageCount
        ? item.packageCount.toInt().toString()
        : item.packageCount.toStringAsFixed(1);

    final sizeLabel = item.packageSize.truncateToDouble() == item.packageSize
        ? item.packageSize.toInt().toString()
        : item.packageSize.toStringAsFixed(1);

    final countUnitLabel = item.packageCount == 1
        ? item.packageTypeLabel.toLowerCase()
        : item.packageTypePlural.toLowerCase();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isLowStock
              ? AppTheme.errorColor.withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Physical Count Badge (e.g. "[5x]")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: item.isLowStock
                        ? AppTheme.errorColor.withValues(alpha: 0.15)
                        : (isDark
                            ? AppTheme.primaryColor.withValues(alpha: 0.18)
                            : AppTheme.primaryLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '[${countLabel}x]',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: item.isLowStock ? AppTheme.errorColor : AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name, Brand, and Unit Specs
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Low Stock',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.brand.isNotEmpty ? "${item.brand} · " : ""}$sizeLabel${item.measurementUnit} per ${item.packageTypeLabel.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Costing Reference details
                      Text(
                        '${formatCurrency(item.packageCost)}/${item.packageTypeLabel.toLowerCase()} · ${formatCurrency(item.costPerUnit)}/${item.measurementUnit}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') _openItemSheet(item: item);
                    if (val == 'delete') _confirmDelete(item);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Item & Price'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 18),

            // Quick Stock Adjust Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Physical Total: ${formatCurrency(item.totalValue)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      color: AppTheme.textSecondary,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Decrease 1 ${item.packageTypeLabel.toLowerCase()}',
                      onPressed: () => service.adjustPackageCount(item.id, -1),
                    ),
                    Text(
                      '$countLabel $countUnitLabel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      color: AppTheme.primaryColor,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Increase 1 ${item.packageTypeLabel.toLowerCase()}',
                      onPressed: () => service.adjustPackageCount(item.id, 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB 2: COSTING & MARGINS ANALYTICS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCostingTab(CostingService service) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (service.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              const Text(
                'Failed to load costing calculations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                service.errorMessage!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => service.loadCostings(),
              ),
            ],
          ),
        ),
      );
    }

    final breakdowns = service.breakdowns;

    return RefreshIndicator(
      onRefresh: () => service.loadCostings(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // Average Margin Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF241F1B) : AppTheme.surfaceDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF382F28)
                    : AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Bakery Margin',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Based on COGS, Labor & Overhead',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: service.averageProfitMarginPct >= 30
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${service.averageProfitMarginPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: service.averageProfitMarginPct >= 30
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (breakdowns.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No products available for costing calculation.'),
            )
          else
            ...breakdowns.map((b) => _buildCostingCard(b)),
        ],
      ),
    );
  }

  Widget _buildCostingCard(ProductCostBreakdown b) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final margin = b.profitMarginPct;
    final isHealthy = margin >= 30.0;
    final isWarning = margin < 30.0 && margin >= 15.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Cake Name + Margin Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selling Price: ${formatCurrency(b.sellingPrice)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? const Color(0xFFECFDF5)
                        : (isWarning ? const Color(0xFFFEF3C7) : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${margin.toStringAsFixed(1)}% Margin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHealthy
                          ? const Color(0xFF047857)
                          : (isWarning ? const Color(0xFFB45309) : const Color(0xFFB91C1C)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Cost Factor Row Chips
            Row(
              children: [
                _buildCostFactorPill(
                  label: 'COGS',
                  amount: b.ingredientCost,
                  icon: Icons.kitchen_outlined,
                ),
                const SizedBox(width: 8),
                _buildCostFactorPill(
                  label: 'Labor',
                  amount: b.laborCost,
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(width: 8),
                _buildCostFactorPill(
                  label: 'Overhead',
                  amount: b.packagingCost + b.overheadCost,
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),

            const Divider(height: 22),

            // Financial Summary Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'True Production Cost',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      formatCurrency(b.totalCost),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net Profit per Cake',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      formatCurrency(b.netProfit),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: b.netProfit >= 0 ? const Color(0xFF10B981) : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Edit Factors'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _openCostingSheet(b),
                ),
              ],
            ),

            // Suggested Price Hint
            if (b.suggestedPrice > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2722) : AppTheme.surfaceDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Suggested Price for ${b.profile.targetMarginPct.toStringAsFixed(0)}% margin: ',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      formatCurrency(b.suggestedPrice),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostFactorPill({
    required String label,
    required double amount,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2722) : AppTheme.surfaceDim,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formatCurrency(amount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
