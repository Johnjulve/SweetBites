import 'package:flutter/material.dart';

import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/product_cost_breakdown.dart';
import '../../models/product_costing_profile.dart';

/// Interactive modal sheet to view and edit labor, packaging, and overhead costs for a cake product.
class CostingEditorSheet extends StatefulWidget {
  final ProductCostBreakdown breakdown;
  final ValueChanged<ProductCostingProfile> onSaved;

  const CostingEditorSheet({
    super.key,
    required this.breakdown,
    required this.onSaved,
  });

  @override
  State<CostingEditorSheet> createState() => _CostingEditorSheetState();
}

class _CostingEditorSheetState extends State<CostingEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _prepTimeController;
  late final TextEditingController _laborRateController;
  late final TextEditingController _packagingController;
  late final TextEditingController _overheadController;
  late final TextEditingController _targetMarginController;

  @override
  void initState() {
    super.initState();
    final profile = widget.breakdown.profile;
    _prepTimeController = TextEditingController(
      text: profile.prepTimeMinutes.toString(),
    );
    _laborRateController = TextEditingController(
      text: profile.hourlyLaborRate > 0 ? profile.hourlyLaborRate.toStringAsFixed(2) : '100.00',
    );
    _packagingController = TextEditingController(
      text: profile.packagingCost.toStringAsFixed(2),
    );
    _overheadController = TextEditingController(
      text: profile.overheadFixedCost.toStringAsFixed(2),
    );
    _targetMarginController = TextEditingController(
      text: profile.targetMarginPct.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _prepTimeController.dispose();
    _laborRateController.dispose();
    _packagingController.dispose();
    _overheadController.dispose();
    _targetMarginController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final prep = int.tryParse(_prepTimeController.text.trim()) ?? 0;
    final rate = double.tryParse(_laborRateController.text.trim()) ?? 0.0;
    final packaging = double.tryParse(_packagingController.text.trim()) ?? 0.0;
    final overhead = double.tryParse(_overheadController.text.trim()) ?? 0.0;
    final margin = double.tryParse(_targetMarginController.text.trim()) ?? 40.0;

    final updated = widget.breakdown.profile.copyWith(
      prepTimeMinutes: prep,
      hourlyLaborRate: rate,
      packagingCost: packaging,
      overheadFixedCost: overhead,
      targetMarginPct: margin,
      updatedAt: DateTime.now(),
    );

    widget.onSaved(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.breakdown;

    // Live preview calculation based on input fields
    final prep = int.tryParse(_prepTimeController.text.trim()) ?? 0;
    final rate = double.tryParse(_laborRateController.text.trim()) ?? 0.0;
    final packaging = double.tryParse(_packagingController.text.trim()) ?? 0.0;
    final overhead = double.tryParse(_overheadController.text.trim()) ?? 0.0;
    final currentLabor = (prep / 60.0) * rate;
    final currentTotalCost = b.ingredientCost + currentLabor + packaging + overhead;
    final currentProfit = b.sellingPrice - currentTotalCost;
    final currentMargin = b.sellingPrice > 0 ? (currentProfit / b.sellingPrice) * 100.0 : 0.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.product.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selling Price: ${formatCurrency(b.sellingPrice)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Real-time Margin & Cost Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF2C241E),
                                const Color(0xFF241C16),
                              ]
                            : [
                                AppTheme.primaryColor.withValues(alpha: 0.08),
                                AppTheme.primaryLight.withValues(alpha: 0.4),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.primaryColor.withValues(alpha: 0.35)
                            : AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'True Total Cost',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formatCurrency(currentTotalCost),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net Profit per Cake',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formatCurrency(currentProfit),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentProfit >= 0
                                    ? const Color(0xFF10B981)
                                    : AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profit Margin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentMargin >= 30
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                    : (currentMargin >= 15
                                        ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                                        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2))),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${currentMargin.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: currentMargin >= 30
                                      ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                      : (currentMargin >= 15
                                          ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309))
                                          : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ingredients COGS Breakdown Section
                  Text(
                    '1. Raw Materials (COGS) — ${formatCurrency(b.ingredientCost)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (b.itemCosts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A231E) : AppTheme.surfaceDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3E332B) : AppTheme.dividerColor,
                        ),
                      ),
                      child: Text(
                        'No recipe items configured. Add ingredients in the Recipe Editor to calculate raw material costs.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHintOf(context),
                        ),
                      ),
                    )
                  else
                    ...b.itemCosts.map((ic) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${ic.item.ingredientName} (${formatQuantity(ic.item.quantity)} ${ic.item.unit})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                formatCurrency(ic.subtotalCost),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Labor Section
                  Text(
                    '2. Labor Factor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prepTimeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Bake / Prep Time',
                            suffixText: 'mins',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _laborRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Hourly Rate',
                            prefixText: '₱ ',
                            suffixText: '/hr',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Packaging & Overhead Section
                  Text(
                    '3. Packaging & Overhead Buffer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _packagingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Box & Packaging',
                            prefixText: '₱ ',
                            hintText: 'e.g. 25.00',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _overheadController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Overhead / Gas',
                            prefixText: '₱ ',
                            hintText: 'e.g. 15.00',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Target Margin % Section
                  TextFormField(
                    controller: _targetMarginController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Target Profit Margin Goal',
                      suffixText: '%',
                      prefixIcon: Icon(Icons.track_changes_outlined),
                      helperText: 'Used to calculate suggested retail prices',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save Cost Profile'),
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
