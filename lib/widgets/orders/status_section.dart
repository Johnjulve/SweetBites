import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../common/status_badge.dart';

/// Renders the current status of an order along with available next action buttons.
class OrderStatusSection extends StatelessWidget {
  final OrderStatus status;
  final bool isUpdating;
  final bool canComplete;
  final String? completeDisabledReason;
  final void Function(OrderStatus target, String label) onStatusSelected;

  const OrderStatusSection({
    super.key,
    required this.status,
    required this.isUpdating,
    this.canComplete = true,
    this.completeDisabledReason,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextStatuses = OrderStatusTransitions.getNextStatuses(status);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: status),
            ],
          ),
          if (nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: nextStatuses.map((target) {
                return _buildStatusButton(context, target);
              }).toList(),
            ),
            if (nextStatuses.contains(OrderStatus.completed) &&
                !canComplete &&
                completeDisabledReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        completeDisabledReason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, OrderStatus target) {
    String label;
    Color color;
    IconData icon;

    switch (target) {
      case OrderStatus.baking:
        label = 'Start Baking';
        color = const Color(0xFFF59E0B);
        icon = Icons.local_fire_department;
      case OrderStatus.ready:
        if (status == OrderStatus.completed) {
          label = 'Revert to Ready';
          color = const Color(0xFF7A6B5D);
          icon = Icons.undo;
        } else {
          label = 'Mark Ready';
          color = const Color(0xFF10B981);
          icon = Icons.check_circle_outline;
        }
      case OrderStatus.completed:
        label = 'Complete';
        color = const Color(0xFF6366F1);
        icon = Icons.done_all;
      case OrderStatus.cancelled:
        label = 'Cancel';
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_outlined;
      default:
        label = target.label;
        color = target.color;
        icon = target.icon;
    }

    final bool isCompletedTarget = target == OrderStatus.completed;
    final bool isButtonDisabled = isUpdating || (isCompletedTarget && !canComplete);

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isButtonDisabled ? null : () => onStatusSelected(target, label),
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
          disabledForegroundColor: Colors.grey.withValues(alpha: 0.5),
          minimumSize: const Size(140, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
