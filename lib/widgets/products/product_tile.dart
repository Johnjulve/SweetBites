import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../models/product.dart';

/// A product selection tile with +/- quantity controls for the order creation screen.
class ProductTile extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = quantity > 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? const Color(0xFFE8734A).withValues(alpha: 0.18)
                : const Color(0xFFFFF0EB))
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFE8734A).withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE8DFD6).withValues(alpha: 0.6)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(product.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8734A),
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      truncateText(product.description, 50),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A6B5D),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Quantity controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Remove button
                _QuantityButton(
                  icon: Icons.remove,
                  onPressed: quantity > 0 ? onRemove : null,
                  isEnabled: quantity > 0,
                ),
                // Quantity display
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: SizedBox(
                    key: ValueKey<int>(quantity),
                    width: 40,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFFE8734A)
                            : const Color(0xFFB5A99A),
                      ),
                    ),
                  ),
                ),
                // Add button
                _QuantityButton(
                  icon: Icons.add,
                  onPressed: onAdd,
                  isEnabled: true,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isPrimary;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.isEnabled,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F0EB);
    final disabledBg = defaultBg.withValues(alpha: 0.5);

    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: isPrimary && isEnabled
            ? const Color(0xFFE8734A)
            : isEnabled
                ? defaultBg
                : disabledBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            size: 22,
            color: isPrimary && isEnabled
                ? Colors.white
                : isEnabled
                    ? theme.colorScheme.onSurface
                    : const Color(0xFFB5A99A),
          ),
        ),
      ),
    );
  }
}
