import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import '../../models/order.dart';

/// Card displaying the customer information and order metadata.
class OrderCustomerInfoSection extends StatelessWidget {
  final Order order;
  final Customer? customer;

  const OrderCustomerInfoSection({
    super.key,
    required this.order,
    this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Card
        _buildCard(
          context,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLightOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? order.customerName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (customer?.phone != null && customer!.phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          customer!.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order Meta Info Card
        _buildCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context, 'Order ID', order.id, selectable: true),
              const Divider(height: 20),
              _buildInfoRow(context, 'Created', formatDateTime(order.createdAt)),
              const Divider(height: 20),
              _buildInfoRow(
                context,
                'Pickup',
                '${formatDateTime(order.pickupDate)}  •  ${formatRelativeDate(order.pickupDate)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
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
      child: child,
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool selectable = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textHintOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: selectable
              ? SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }
}
