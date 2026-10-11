import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/widgets.dart';

/// Screen that provides a digital view of the order receipt (rendered as a physical
/// thermal receipt) and offers actions to print or share it as a PNG image.
class ReceiptPreviewScreen extends StatefulWidget {
  final String orderId;

  const ReceiptPreviewScreen({super.key, required this.orderId});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isLoading = true;
  Order? _order;
  Customer? _customer;
  PaymentSummary? _paymentSummary;
  String _bakeryName = '';
  String _bakeryAddress = '';
  String _bakeryPhone = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceiptData();
  }

  Future<void> _loadReceiptData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderService = context.read<OrderService>();
      final paymentService = context.read<PaymentService>();

      // 1. Fetch order details
      final order = await orderService.getOrderById(widget.orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // 2. Fetch customer details
      final customer = await orderService.getCustomerForOrder(order.customerId);
      if (customer == null) {
        throw Exception('Customer details not found');
      }

      // 3. Fetch payment summary
      final paymentSummary = await paymentService.getPaymentSummary(
        order.id,
        order.totalAmount,
      );

      // 4. Fetch bakery settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bakeryName =
          prefs.getString(AppConstants.prefBakeryName) ??
          AppConstants.defaultBakeryName;
      final bakeryAddress =
          prefs.getString(AppConstants.prefBakeryAddress) ??
          AppConstants.defaultBakeryAddress;
      final bakeryPhone =
          prefs.getString(AppConstants.prefBakeryPhone) ??
          AppConstants.defaultBakeryPhone;

      if (mounted) {
        setState(() {
          _order = order;
          _customer = customer;
          _paymentSummary = paymentSummary;
          _bakeryName = bakeryName;
          _bakeryAddress = bakeryAddress;
          _bakeryPhone = bakeryPhone;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> _capturePngBytes() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing PNG: $e');
      return null;
    }
  }

  Future<void> _printReceipt() async {
    final pngBytes = await _capturePngBytes();
    if (pngBytes == null || _order == null) return;

    try {
      final pdf = pw.Document();
      final image = pw.MemoryImage(pngBytes);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Receipt_${shortOrderId(_order!.id)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print receipt: $e')),
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    final pngBytes = await _capturePngBytes();
    if (pngBytes == null || _order == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final shortId = shortOrderId(_order!.id);
      final file = File('${tempDir.path}/receipt_$shortId.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          text: 'Receipt for order $shortId from SweetBites',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share receipt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order != null
              ? 'Receipt: ${shortOrderId(_order!.id)}'
              : 'Receipt Preview',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadReceiptData,
          ),
        ],
      ),
      body: _buildBody(theme),
      bottomNavigationBar: _order == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareReceipt,
                        icon: const Icon(Icons.share),
                        label: const Text('Share PNG'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _printReceipt,
                        icon: const Icon(Icons.print),
                        label: const Text('Print Receipt'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading receipt data...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading receipt',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadReceiptData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null || _customer == null || _paymentSummary == null) {
      return const Center(child: Text('No receipt content available'));
    }

    return Container(
      color: const Color(0xFFEFECE9), // Countertop background
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: ThermalReceiptView(
            order: _order!,
            customer: _customer!,
            paymentSummary: _paymentSummary!,
            bakeryName: _bakeryName,
            bakeryAddress: _bakeryAddress,
            bakeryPhone: _bakeryPhone,
            repaintBoundaryKey: _boundaryKey,
          ),
        ),
      ),
    );
  }
}
