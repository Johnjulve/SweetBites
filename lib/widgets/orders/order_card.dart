import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../models/order.dart';
import '../common/status_badge.dart';

/// A card widget displaying an order summary for list views.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Order ID + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shortOrderId(order.id),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),

              // Customer name
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Unknown Customer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom row: items count + pickup date + total + arrow
              Row(
                children: [
                  // Items count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pickup date
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${formatRelativeDate(order.pickupDate)} ${formatTime(order.pickupDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const Spacer(),

                  // Total
                  Text(
                    formatCurrency(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8734A),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Receipt Shortcut Button
                  IconButton(
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: Color(0xFF7A6B5D),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/receipt',
                        arguments: order.id,
                      );
                    },
                    tooltip: 'View Receipt',
                  ),
                  const SizedBox(width: 8),

                  // Arrow
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFB5A99A),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
