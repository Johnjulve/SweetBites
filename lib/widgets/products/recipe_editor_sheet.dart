import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/inventory_item.dart';
import '../../models/product.dart';
import '../../models/recipe.dart';
import '../../services/costing_service.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';

/// Modal bottom sheet for creating, editing, and managing ingredients of a product's recipe.
class RecipeEditorSheet extends StatefulWidget {
  final Product product;
  final VoidCallback onSaved;

  const RecipeEditorSheet({
    super.key,
    required this.product,
    required this.onSaved,
  });

  @override
  State<RecipeEditorSheet> createState() => _RecipeEditorSheetState();
}

class _RecipeEditorSheetState extends State<RecipeEditorSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  Recipe? _recipe;
  final List<_IngredientEntry> _ingredients = [];
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  String _selectedUnit = 'g';
  String? _selectedInventoryItemId;

  static const List<String> _units = [
    'g',
    'kg',
    'ml',
    'L',
    'pcs',
    'cups',
    'tbsp',
    'tsp',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    try {
      final productService = context.read<ProductService>();
      final recipe = await productService.getRecipe(widget.product.id);
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        if (recipe != null) {
          _ingredients.clear();
          for (final item in recipe.items) {
            _ingredients.add(
              _IngredientEntry(
                name: item.ingredientName,
                quantity: item.quantity,
                unit: item.unit,
                inventoryItemId: item.inventoryItemId,
              ),
            );
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showPantryLinkerDialog({
    required String ingredientName,
    required ValueChanged<InventoryItem?> onSelected,
  }) async {
    final invService = context.read<InventoryService>();
    final items = invService.items;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final q = ingredientName.trim().toLowerCase();

        final sortedItems = List<InventoryItem>.from(items)
          ..sort((a, b) {
            final aMatch = (a.name.toLowerCase().contains(q) || q.contains(a.name.toLowerCase())) ? 0 : 1;
            final bMatch = (b.name.toLowerCase().contains(q) || q.contains(b.name.toLowerCase())) ? 0 : 1;
            if (aMatch != bMatch) return aMatch.compareTo(bMatch);
            final aStock = a.packageCount > 0 ? 0 : 1;
            final bStock = b.packageCount > 0 ? 0 : 1;
            if (aStock != bStock) return aStock.compareTo(bStock);
            return a.name.compareTo(b.name);
          });

        return AlertDialog(
          title: Text(
            ingredientName.isNotEmpty ? 'Link "$ingredientName" to Stock' : 'Select Pantry Item',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose which pantry brand to link for live stock tracking and recipe costing:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sortedItems.isEmpty
                      ? Center(
                          child: Text(
                            'No inventory items found.\nAdd items in the Pantry & Stock tab first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textHintOf(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: sortedItems.length,
                          separatorBuilder: (_, index) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final item = sortedItems[i];
                            final hasStock = item.packageCount > 0;
                            final brandLabel = item.brand.isNotEmpty ? item.brand : 'No brand';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: hasStock
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                    : (isDark ? const Color(0xFF382F28) : const Color(0xFFF3F4F6)),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                  color: hasStock ? const Color(0xFF10B981) : AppTheme.textHint,
                                ),
                              ),
                              title: Text(
                                '${item.name} ($brandLabel)',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${item.packageSize}${item.measurementUnit} · ${formatCurrency(item.costPerUnit)}/${item.measurementUnit} · ${item.packageCount.toStringAsFixed(item.packageCount.truncateToDouble() == item.packageCount ? 0 : 1)} in stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: hasStock
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                      : (isDark ? const Color(0xFF3E2D22) : const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hasStock ? 'In Stock' : '0 Stock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: hasStock
                                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
                                  ),
                                ),
                              ),
                              onTap: () {
                                onSelected(item);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                onSelected(null);
                Navigator.pop(ctx);
              },
              child: const Text('Unlink (Custom Only)'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addIngredient() {
    final name = _nameController.text.trim();
    final qty = parseFractionOrDecimal(_qtyController.text.trim());
    if (name.isEmpty || qty <= 0) return;

    // Check if an inventory item matches by name if not already explicitly selected
    String? invId = _selectedInventoryItemId;
    if (invId == null) {
      final invService = context.read<InventoryService>();
      final matches = invService.items.where(
        (i) {
          final q = name.toLowerCase();
          final iName = i.name.toLowerCase();
          final iBrand = i.brand.toLowerCase();
          return iName == q || iName.contains(q) || q.contains(iName) || '$iBrand $iName'.contains(q);
        },
      ).toList();
      if (matches.isNotEmpty) {
        invId = matches.firstWhere((m) => m.packageCount > 0, orElse: () => matches.first).id;
      }
    }

    setState(() {
      _ingredients.add(
        _IngredientEntry(
          name: name,
          quantity: qty,
          unit: _selectedUnit,
          inventoryItemId: invId,
        ),
      );
      _nameController.clear();
      _qtyController.clear();
      _selectedInventoryItemId = null;
    });
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
  }

  Future<void> _saveRecipe() async {
    setState(() => _isSaving = true);
    try {
      final productService = context.read<ProductService>();

      final recipeId = _recipe?.id ?? generateId();
      final items = _ingredients.map((entry) {
        return RecipeItem(
          recipeId: recipeId,
          ingredientName: entry.name,
          quantity: entry.quantity,
          unit: entry.unit,
          inventoryItemId: entry.inventoryItemId,
        );
      }).toList();

      final recipe = Recipe(
        id: recipeId,
        productId: widget.product.id,
        items: items,
      );

      await productService.saveRecipe(recipe);
      if (mounted) {
        context.read<CostingService>().loadCostings();
      }
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.dividerOf(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recipe – ${widget.product.name}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Ingredients list
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (_ingredients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No ingredients yet. Add some below.',
                            style: TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ..._ingredients.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ingredient = entry.value;
                          final invService = context.watch<InventoryService>();
                          final linked = ingredient.inventoryItemId != null
                              ? invService.items.where((i) => i.id == ingredient.inventoryItemId).firstOrNull
                              : null;

                          // Fallback smart auto-match if not explicitly linked
                          final autoCandidates = linked != null
                              ? <InventoryItem>[]
                              : invService.items.where((i) {
                                  final q = ingredient.name.trim().toLowerCase();
                                  final iName = i.name.toLowerCase();
                                  final iBrand = i.brand.toLowerCase();
                                  return iName == q || iName.contains(q) || q.contains(iName) || '$iBrand $iName'.contains(q);
                                }).toList();

                          final autoMatch = autoCandidates.isNotEmpty
                              ? autoCandidates.firstWhere((c) => c.packageCount > 0, orElse: () => autoCandidates.first)
                              : null;

                          final effectiveItem = linked ?? autoMatch;
                          final convertedQty = effectiveItem != null
                              ? convertMeasurementUnit(ingredient.quantity, ingredient.unit, effectiveItem.measurementUnit)
                              : ingredient.quantity;
                          final costPreview = effectiveItem != null
                              ? convertedQty * effectiveItem.costPerUnit
                              : null;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Text(
                                  ingredient.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    _showPantryLinkerDialog(
                                      ingredientName: ingredient.name,
                                      onSelected: (picked) {
                                        setState(() {
                                          _ingredients[idx] = _IngredientEntry(
                                            name: ingredient.name,
                                            quantity: ingredient.quantity,
                                            unit: ingredient.unit,
                                            inventoryItemId: picked?.id,
                                          );
                                        });
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: linked != null
                                          ? AppTheme.primaryLightOf(context)
                                          : (autoMatch != null
                                              ? (Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF2E241E)
                                                  : const Color(0xFFFFF7ED))
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF2E2722)
                                                  : AppTheme.surfaceDim)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: linked != null
                                            ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                            : (autoMatch != null
                                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                                : Theme.of(context).dividerColor),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          linked != null
                                              ? Icons.link
                                              : (autoMatch != null ? Icons.auto_awesome : Icons.link_off),
                                          size: 11,
                                          color: linked != null
                                              ? AppTheme.primaryColor
                                              : (autoMatch != null ? AppTheme.primaryColor : AppTheme.textHint),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          linked != null
                                              ? '${linked.brand.isNotEmpty ? linked.brand : linked.name} (${linked.packageCount.toInt()} in stock)'
                                              : (autoMatch != null
                                                  ? 'Auto: ${autoMatch.brand.isNotEmpty ? autoMatch.brand : autoMatch.name}'
                                                  : '+ Link Brand'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: linked != null
                                                ? AppTheme.primaryColor
                                                : (autoMatch != null
                                                    ? AppTheme.primaryColor
                                                    : AppTheme.textSecondaryOf(context)),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 14,
                                          color: linked != null ? AppTheme.primaryColor : AppTheme.textHint,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              costPreview != null
                                  ? '${formatQuantity(ingredient.quantity)} ${ingredient.unit}  •  ${formatCurrency(costPreview)}'
                                  : '${formatQuantity(ingredient.quantity)} ${ingredient.unit}',
                              style: TextStyle(
                                color: AppTheme.textSecondaryOf(context),
                                fontSize: 13,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.errorColor,
                                size: 22,
                              ),
                              onPressed: () => _removeIngredient(idx),
                            ),
                          );
                        }),

                      const Divider(height: 24),

                      // Add ingredient controls header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Ingredient',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              _showPantryLinkerDialog(
                                ingredientName: _nameController.text,
                                onSelected: (item) {
                                  if (item != null) {
                                    setState(() {
                                      _nameController.text = item.name;
                                      _selectedInventoryItemId = item.id;
                                      if (_units.contains(item.measurementUnit)) {
                                        _selectedUnit = item.measurementUnit;
                                      }
                                    });
                                  }
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Select from Stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_selectedInventoryItemId != null) ...[
                        Builder(
                          builder: (ctx) {
                            final invService = context.watch<InventoryService>();
                            final picked = invService.items.where((i) => i.id == _selectedInventoryItemId).firstOrNull;
                            if (picked == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLightOf(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link, size: 14, color: AppTheme.primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Linked to: ${picked.brand.isNotEmpty ? picked.brand : picked.name} (${picked.packageSize}${picked.measurementUnit} · ${picked.packageCount.toInt()} in stock)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedInventoryItemId = null;
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 14, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // Quick fraction presets row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['1/8', '1/4', '1/3', '1/2', '3/4', '1', '1 1/2', '2'].map((frac) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    setState(() {
                                      _qtyController.text = frac;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF2E2722)
                                          : AppTheme.surfaceDim,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Text(
                                      frac,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Add ingredient inputs row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Ingredient',
                                isDense: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _qtyController,
                              decoration: const InputDecoration(
                                hintText: 'Qty (1 1/2)',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                              ),
                              items: _units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(
                                        u,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedUnit = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 44,
                            height: 48,
                            child: IconButton(
                              onPressed: _addIngredient,
                              icon: const Icon(
                                Icons.add_circle,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRecipe,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Recipe'),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _IngredientEntry {
  final String name;
  final double quantity;
  final String unit;
  final String? inventoryItemId;

  _IngredientEntry({
    required this.name,
    required this.quantity,
    required this.unit,
    this.inventoryItemId,
  });
}
