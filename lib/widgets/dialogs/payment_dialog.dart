import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../models/payment.dart';

/// A dialog for recording a payment against an order.
class PaymentDialog extends StatefulWidget {
  final String orderId;
  final double balance;

  const PaymentDialog({
    super.key,
    required this.orderId,
    required this.balance,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  final TextEditingController _referenceController = TextEditingController();
  String _paymentMethod = 'cash';
  final _formKey = GlobalKey<FormState>();

  static const List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'gcash', 'label': 'GCash'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.balance.toStringAsFixed(2),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    
    String finalNotes = _notesController.text.trim();
    if (_paymentMethod != 'cash') {
      final refNo = _referenceController.text.trim();
      if (refNo.isNotEmpty) {
        finalNotes = finalNotes.isNotEmpty 
            ? 'Ref: $refNo ($finalNotes)' 
            : 'Ref: $refNo';
      }
    }

    final payment = Payment(
      orderId: widget.orderId,
      amountPaid: amount,
      paymentMethod: _paymentMethod,
      notes: finalNotes,
    );

    Navigator.of(context).pop(payment);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D1B0E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Balance remaining
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Balance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      formatCurrency(widget.balance),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amount > widget.balance + 0.01) {
                    return 'Amount exceeds remaining balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment method dropdown
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: _paymentMethods
                    .map(
                      (m) => DropdownMenuItem(
                        value: m['value'],
                        child: Text(m['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Reference Number field (GCash / Bank Transfer)
              if (_paymentMethod != 'cash') ...[
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number *',
                    hintText: 'e.g. 12-digit transaction ID',
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the reference number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., deposit, final payment',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Record'),
                    ),
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
