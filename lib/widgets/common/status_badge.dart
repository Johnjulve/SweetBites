import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// A compact chip that displays an order status with a matching
/// icon, label, and colour scheme.
///
/// Uses the [OrderStatus] enum's built-in display properties
/// (label, color, backgroundColor, icon) so colours stay consistent
/// across the entire app.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    this.status,
    this.paymentStatus,
  }) : assert(status != null || paymentStatus != null, 'Must provide either status or paymentStatus');

  /// The order status to display.
  final OrderStatus? status;

  /// The payment status to display.
  final PaymentStatus? paymentStatus;

  @override
  Widget build(BuildContext context) {
    final label = status?.label ?? paymentStatus!.label;
    final color = status?.color ?? paymentStatus!.color;
    final backgroundColor = status?.backgroundColor ?? paymentStatus!.backgroundColor;
    final icon = status?.icon ?? paymentStatus!.icon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
