import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../common/status_badge.dart';

/// Renders payment summary, payment breakdown list, and payment actions.
class OrderPaymentSection extends StatelessWidget {
  final Order order;
  final PaymentSummary paymentSummary;
  final VoidCallback onRecordPayment;
  final void Function(Payment payment) onVoidPayment;

  const OrderPaymentSection({
    super.key,
    required this.order,
    required this.paymentSummary,
    required this.onRecordPayment,
    required this.onVoidPayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentStatus = PaymentStatus.fromString(paymentSummary.status);

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
                'Payment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(paymentStatus: paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentRow(context, 'Total', formatCurrency(paymentSummary.totalAmount)),
          const SizedBox(height: 6),
          _buildPaymentRow(
            context,
            'Paid',
            formatCurrency(paymentSummary.totalPaid),
            valueColor: AppTheme.successColor,
          ),
          const SizedBox(height: 6),
          _buildPaymentRow(
            context,
            'Balance',
            formatCurrency(paymentSummary.balance),
            valueColor: paymentSummary.balance > 0
                ? AppTheme.errorColor
                : AppTheme.successColor,
            isBold: true,
          ),
          if (paymentSummary.payments.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Payment History',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            ...paymentSummary.payments.map((payment) {
              final isVoided = payment.isVoided;
              final textDecoration =
                  isVoided ? TextDecoration.lineThrough : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isVoided
                            ? AppTheme.surfaceDimOf(context).withValues(alpha: 0.4)
                            : AppTheme.surfaceDimOf(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment.paymentMethod.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isVoided
                              ? AppTheme.textHintOf(context)
                              : AppTheme.textSecondaryOf(context),
                          decoration: textDecoration,
                        ),
                      ),
                    ),
                    if (isVoided) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'VOIDED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDateTime(payment.paidAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: isVoided
                                  ? AppTheme.textHintOf(context).withValues(alpha: 0.6)
                                  : AppTheme.textHintOf(context),
                              decoration: textDecoration,
                            ),
                          ),
                          if (payment.notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                payment.notes,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isVoided
                                      ? AppTheme.textSecondaryOf(context)
                                          .withValues(alpha: 0.6)
                                      : AppTheme.textSecondaryOf(context),
                                  fontStyle: FontStyle.italic,
                                  decoration: textDecoration,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(payment.amountPaid),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isVoided
                            ? AppTheme.textSecondaryOf(context)
                            : theme.colorScheme.onSurface,
                        decoration: textDecoration,
                      ),
                    ),
                    if (!isVoided &&
                        order.status != OrderStatus.cancelled &&
                        order.status != OrderStatus.completed) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.do_not_disturb_on_outlined,
                            size: 20),
                        color: AppTheme.errorColor,
                        tooltip: 'Void Payment',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onVoidPayment(payment),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          if (paymentSummary.balance > 0.01 &&
              order.status != OrderStatus.cancelled &&
              order.status != OrderStatus.completed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onRecordPayment,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Record Payment'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryOf(context),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
