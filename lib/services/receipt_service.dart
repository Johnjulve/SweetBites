import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/helpers.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/payment.dart';

/// Generates professional PDF receipts for bakery orders.
///
/// This is a stateless utility — not a ChangeNotifier — because receipt
/// generation is a one-shot operation with no ongoing state.
class ReceiptService {
  /// Generates a PDF receipt and returns the raw bytes.
  ///
  /// The receipt includes a branded header, order & customer details,
  /// an items table with subtotals, payment summary, and a thank-you footer.
  Future<Uint8List> generateReceipt({
    required Order order,
    required Customer customer,
    required PaymentSummary paymentSummary,
    required String bakeryName,
    String? bakeryAddress,
    String? bakeryPhone,
  }) async {
    final pdf = pw.Document();

    // ── Reusable styles ──────────────────────────────────────────
    final titleStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );
    final headerStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey600);
    final valueStyle = const pw.TextStyle(fontSize: 10);
    final boldValue = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final totalStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────
              pw.Center(child: pw.Text(bakeryName, style: titleStyle)),
              if (bakeryAddress != null && bakeryAddress.isNotEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(bakeryAddress, style: headerStyle),
                  ),
                ),
              if (bakeryPhone != null && bakeryPhone.isNotEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text('Tel: $bakeryPhone', style: headerStyle),
                  ),
                ),
              pw.SizedBox(height: 12),
              _buildDivider(),

              // ── Order Info ───────────────────────────────────────
              pw.SizedBox(height: 10),
              _buildInfoRow(
                'Order ID',
                shortOrderId(order.id),
                labelStyle,
                boldValue,
              ),
              _buildInfoRow(
                'Date',
                formatDateTime(order.createdAt),
                labelStyle,
                valueStyle,
              ),
              _buildInfoRow(
                'Pickup Date',
                formatDate(order.pickupDate),
                labelStyle,
                valueStyle,
              ),

              // ── Customer Info ────────────────────────────────────
              pw.SizedBox(height: 8),
              _buildInfoRow('Customer', customer.name, labelStyle, valueStyle),
              if (customer.phone.isNotEmpty)
                _buildInfoRow('Phone', customer.phone, labelStyle, valueStyle),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // ── Items Table ──────────────────────────────────────
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                headers: ['Product', 'Qty', 'Price', 'Subtotal'],
                data:
                    order.items
                        .map(
                          (item) => [
                            item.productName ?? item.productId,
                            item.quantity.toString(),
                            formatCurrency(item.unitPrice),
                            formatCurrency(item.subtotal),
                          ],
                        )
                        .toList(),
              ),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // ── Total ────────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('Total: ', style: totalStyle),
                    pw.Text(
                      formatCurrency(order.totalAmount),
                      style: totalStyle,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ── Payment Status ───────────────────────────────────
              _buildInfoRow(
                'Payment Status',
                paymentSummary.status.toUpperCase(),
                labelStyle,
                pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color:
                      paymentSummary.status == 'paid'
                          ? PdfColors.green700
                          : paymentSummary.status == 'partial'
                          ? PdfColors.orange700
                          : PdfColors.red700,
                ),
              ),
              _buildInfoRow(
                'Amount Paid',
                formatCurrency(paymentSummary.totalPaid),
                labelStyle,
                valueStyle,
              ),
              if (paymentSummary.balance > 0)
                _buildInfoRow(
                  'Balance Due',
                  formatCurrency(paymentSummary.balance),
                  labelStyle,
                  pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),

              pw.SizedBox(height: 16),
              _buildDivider(),
              pw.SizedBox(height: 16),

              // ── Footer ───────────────────────────────────────────
              pw.Center(
                child: pw.Text(
                  'Thank you for choosing $bakeryName!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Private Helpers ────────────────────────────────────────────

  static pw.Widget _buildDivider() {
    return pw.Divider(thickness: 0.5, color: PdfColors.grey400);
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 100, child: pw.Text('$label:', style: labelStyle)),
          pw.Expanded(child: pw.Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
