import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/payment.dart';

/// Visual representation of the thermal paper receipt.
class ThermalReceiptView extends StatelessWidget {
  final Order order;
  final Customer customer;
  final PaymentSummary paymentSummary;
  final String bakeryName;
  final String bakeryAddress;
  final String bakeryPhone;
  final GlobalKey repaintBoundaryKey;

  const ThermalReceiptView({
    super.key,
    required this.order,
    required this.customer,
    required this.paymentSummary,
    required this.bakeryName,
    required this.bakeryAddress,
    required this.bakeryPhone,
    required this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: Container(
        width: 330,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipPath(
          clipper: JaggedEdgeClipper(),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Logo / Icon
                const Icon(Icons.cake, size: 36, color: Color(0xFF2D1B0E)),
                const SizedBox(height: 8),

                // Bakery Details
                Text(
                  bakeryName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B0E),
                    letterSpacing: 0.5,
                  ),
                ),
                if (bakeryAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bakeryAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF7A6B5D),
                    ),
                  ),
                ],
                if (bakeryPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tel: $bakeryPhone',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF7A6B5D),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                _buildDottedLine(),
                const SizedBox(height: 4),

                // Date / Time
                Text(
                  formatDateTime(DateTime.now()),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF7A6B5D),
                  ),
                ),
                const SizedBox(height: 12),

                // Order Token Box
                CustomPaint(
                  painter: DashedRectPainter(
                    color: const Color(0xFF7A6B5D),
                    strokeWidth: 1.0,
                    gap: 4.0,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ORDER ID',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7A6B5D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortOrderId(order.id),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1B0E),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Info
                _buildMonospacedRow('Customer:', customer.name),
                if (customer.phone.isNotEmpty)
                  _buildMonospacedRow('Phone:', customer.phone),
                _buildMonospacedRow(
                  'Pickup Date:',
                  formatDate(order.pickupDate),
                ),

                _buildDottedLine(),

                // Items List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'ITEM',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1B0E),
                      ),
                    ),
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1B0E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName ?? 'Product',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1B0E),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '  ${item.quantity} x ${formatCurrency(item.unitPrice)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Color(0xFF7A6B5D),
                              ),
                            ),
                            Text(
                              formatCurrency(item.subtotal),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: Color(0xFF2D1B0E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                _buildDottedLine(),

                // Payment summary
                _buildMonospacedRow(
                  'Total Amount:',
                  formatCurrency(paymentSummary.totalAmount),
                ),
                _buildMonospacedRow(
                  'Amount Paid:',
                  formatCurrency(paymentSummary.totalPaid),
                  valueColor: AppTheme.successColor,
                ),
                if (paymentSummary.balance > 0)
                  _buildMonospacedRow(
                    'Balance Due:',
                    formatCurrency(paymentSummary.balance),
                    valueColor: AppTheme.errorColor,
                    isBold: true,
                  ),
                _buildMonospacedRow(
                  'Status:',
                  paymentSummary.status.toUpperCase(),
                  isBold: true,
                  valueColor: paymentSummary.status == 'paid'
                      ? AppTheme.successColor
                      : paymentSummary.status == 'partial'
                          ? Colors.orange
                          : AppTheme.errorColor,
                ),

                _buildDottedLine(),
                const SizedBox(height: 8),

                // Footer logo
                const Text(
                  'SWEETBITES',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF2D1B0E),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thank you for your order!',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF7A6B5D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedLine() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '----------------------------------------',
        style: TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFFB5A99A),
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildMonospacedRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: const Color(0xFF7A6B5D),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: valueColor ?? const Color(0xFF2D1B0E),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to paint a dashed rectangle border.
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = const Color(0xFF7A6B5D),
    this.strokeWidth = 1.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Top
    double x = 0;
    while (x < size.width) {
      path.moveTo(x, 0);
      path.lineTo((x + gap).clamp(0, size.width), 0);
      x += gap * 2;
    }

    // Bottom
    x = 0;
    while (x < size.width) {
      path.moveTo(x, size.height);
      path.lineTo((x + gap).clamp(0, size.width), size.height);
      x += gap * 2;
    }

    // Left
    double y = 0;
    while (y < size.height) {
      path.moveTo(0, y);
      path.lineTo(0, (y + gap).clamp(0, size.height));
      y += gap * 2;
    }

    // Right
    y = 0;
    while (y < size.height) {
      path.moveTo(size.width, y);
      path.lineTo(size.width, (y + gap).clamp(0, size.height));
      y += gap * 2;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom clipper to create a realistic jagged (torn paper) bottom edge.
class JaggedEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 8);

    double x = 0;
    const double waveWidth = 8;
    const double waveHeight = 6;
    bool up = true;

    while (x < size.width) {
      x += waveWidth;
      final y = up ? size.height : (size.height - waveHeight);
      path.lineTo(x.clamp(0, size.width), y);
      up = !up;
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
