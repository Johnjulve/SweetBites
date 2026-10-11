import 'package:flutter/material.dart';

import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/recipe.dart';

/// An expandable checklist showing recipe ingredients with checkboxes.
///
/// Renders as an [ExpansionTile] with a visual progress indicator
/// (e.g. "3/5 items checked") in the title row. Each ingredient
/// shows a checkbox, name, and quantity with unit. Toggling a
/// checkbox invokes [onItemToggled] with the item's ID and new
/// checked state.
class RecipeChecklist extends StatelessWidget {
  const RecipeChecklist({
    super.key,
    required this.recipe,
    this.onItemToggled,
    this.productName,
    this.initiallyExpanded = false,
    this.quantity = 1,
  });

  /// The recipe whose items to display.
  final Recipe recipe;

  /// Called when a checkbox is toggled. Provides the item ID and the
  /// new checked state.
  final void Function(String itemId, bool checked)? onItemToggled;

  /// Optional product name to display as the tile title. Falls back
  /// to "Recipe" if not provided.
  final String? productName;

  /// Whether the tile starts expanded.
  final bool initiallyExpanded;

  /// Multiplier for scaling ingredient quantities.
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final items = recipe.items;
    final checkedCount = items.where((i) => i.isChecked).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppTheme.surfaceDimOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Theme(
        // Remove the default ExpansionTile divider lines.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          shape: const Border(),
          collapsedShape: const Border(),

          // ── Title row ─────────────────────────────────────────
          title: Row(
            children: [
              Expanded(
                child: Text(
                  productName ?? 'Recipe',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ProgressBadge(
                checked: checkedCount,
                total: totalCount,
                progress: progress,
              ),
            ],
          ),

          // ── Ingredient list ───────────────────────────────────
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No ingredients added yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ]
              : items
                  .map(
                    (item) => _IngredientRow(
                      item: item,
                      multiplier: quantity,
                      onToggled: onItemToggled != null
                          ? (checked) => onItemToggled!(item.id, checked)
                          : null,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

/// A single ingredient row with a checkbox, name, and quantity label.
class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.item,
    required this.multiplier,
    required this.onToggled,
  });

  final RecipeItem item;
  final int multiplier;
  final ValueChanged<bool>? onToggled;

  @override
  Widget build(BuildContext context) {
    final scaledQuantity = item.quantity * multiplier;
    final quantityText = scaledQuantity > 0
        ? '${formatQuantity(scaledQuantity)} ${item.unit}'.trim()
        : '';

    return InkWell(
      onTap: onToggled != null ? () => onToggled!(!item.isChecked) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // ── Checkbox ─────────────────────────────────────────
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: item.isChecked,
                onChanged: onToggled != null ? (value) => onToggled!(value ?? false) : null,
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // ── Ingredient name ──────────────────────────────────
            Expanded(
              child: Text(
                item.ingredientName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: item.isChecked
                      ? AppTheme.textHintOf(context)
                      : Theme.of(context).colorScheme.onSurface,
                  decoration: item.isChecked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),

            // ── Quantity label ───────────────────────────────────
            if (quantityText.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDimOf(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quantityText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small badge showing progress like "3/5" with a coloured tint.
class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.checked,
    required this.total,
    required this.progress,
  });

  final int checked;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final bool allDone = total > 0 && checked == total;
    final Color badgeColor =
        allDone ? AppTheme.successColor : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allDone)
            Icon(Icons.check_circle_rounded, size: 14, color: badgeColor),
          if (allDone) const SizedBox(width: 4),
          Text(
            '$checked/$total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
