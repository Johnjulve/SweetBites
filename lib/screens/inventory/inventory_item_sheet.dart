import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/inventory_item.dart';

/// Modal bottom sheet to add or edit an inventory pantry item.
class InventoryItemSheet extends StatefulWidget {
  final InventoryItem? item;
  final ValueChanged<InventoryItem> onSaved;

  const InventoryItemSheet({
    super.key,
    this.item,
    required this.onSaved,
  });

  @override
  State<InventoryItemSheet> createState() => _InventoryItemSheetState();
}

class _InventoryItemSheetState extends State<InventoryItemSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _categoryController;
  late final TextEditingController _packageTypeController;
  late final TextEditingController _countController;
  late final TextEditingController _sizeController;
  late final TextEditingController _unitController;
  late final TextEditingController _costController;
  late final TextEditingController _minAlertController;

  static const List<String> _suggestedCategories = [
    'Dairy',
    'Dry Goods',
    'Fats & Oils',
    'Flavoring',
    'Packaging',
    'Other',
  ];

  static const List<String> _suggestedPackageTypes = [
    'Can',
    'Bottle',
    'Pack',
    'Sachet',
    'Pouch',
    'Box',
    'Bar',
    'Tub',
    'Piece',
  ];

  static const List<String> _suggestedUnits = [
    'ml',
    'g',
    'kg',
    'L',
    'pcs',
  ];

  String _packagePlural(String singular) {
    final lower = singular.toLowerCase();
    if (lower == 'box') return 'Boxes';
    if (lower == 'pouch') return 'Pouches';
    if (lower == 'piece') return 'Pieces';
    if (lower.endsWith('s')) return singular;
    return '${singular}s';
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _categoryController = TextEditingController(text: item?.category ?? 'Dry Goods');
    _packageTypeController = TextEditingController(text: item?.packageTypeLabel ?? 'Pack');
    _countController = TextEditingController(
      text: item != null ? item.packageCount.toStringAsFixed(item.packageCount.truncateToDouble() == item.packageCount ? 0 : 1) : '1',
    );
    _sizeController = TextEditingController(
      text: item != null ? item.packageSize.toStringAsFixed(item.packageSize.truncateToDouble() == item.packageSize ? 0 : 1) : '1000',
    );
    _unitController = TextEditingController(text: item?.measurementUnit ?? 'g');
    _costController = TextEditingController(
      text: item != null ? item.packageCost.toStringAsFixed(2) : '0.00',
    );
    _minAlertController = TextEditingController(
      text: item != null ? item.minStockAlert.toStringAsFixed(item.minStockAlert.truncateToDouble() == item.minStockAlert ? 0 : 1) : '2',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _packageTypeController.dispose();
    _countController.dispose();
    _sizeController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _minAlertController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final category = _categoryController.text.trim().isEmpty ? 'Other' : _categoryController.text.trim();
    final packageType = _packageTypeController.text.trim().isEmpty ? 'Pack' : _packageTypeController.text.trim();
    final count = double.tryParse(_countController.text.trim()) ?? 0.0;
    final size = double.tryParse(_sizeController.text.trim()) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty ? 'g' : _unitController.text.trim();
    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
    final minAlert = double.tryParse(_minAlertController.text.trim()) ?? 0.0;

    final updated = (widget.item ?? InventoryItem(
      name: name,
      category: category,
      packageType: packageType,
      packageSize: size,
      measurementUnit: unit,
      packageCost: cost,
    )).copyWith(
      name: name,
      brand: brand,
      category: category,
      packageType: packageType,
      packageCount: count,
      packageSize: size,
      measurementUnit: unit,
      packageCost: cost,
      minStockAlert: minAlert,
      updatedAt: DateTime.now(),
    );

    widget.onSaved(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.item != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Inventory Item' : 'New Pantry Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pantry package & pricing details',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Ingredient Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item / Ingredient Name *',
                      hintText: 'e.g. Evaporated Milk, Cake Flour',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Brand & Category Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            hintText: 'e.g. Nestle, Maya',
                            prefixIcon: Icon(Icons.branding_watermark_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _suggestedCategories.contains(_categoryController.text)
                              ? _categoryController.text
                              : _suggestedCategories.first,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _suggestedCategories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _categoryController.text = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Package & Costing Reference Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDimOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calculate_outlined, size: 18, color: AppTheme.primaryColor),
                            SizedBox(width: 6),
                            Text(
                              'Package Specifications & Cost',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _suggestedPackageTypes.contains(_packageTypeController.text)
                              ? _packageTypeController.text
                              : _suggestedPackageTypes.first,
                          decoration: const InputDecoration(
                            labelText: 'Packaging / Container Type',
                            prefixIcon: Icon(Icons.all_inbox_outlined),
                          ),
                          items: _suggestedPackageTypes
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _packageTypeController.text = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _sizeController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Size / Net per ${_packageTypeController.text} *',
                                  hintText: 'e.g. 360',
                                ),
                                validator: (v) {
                                  final num = double.tryParse(v ?? '');
                                  if (num == null || num <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _suggestedUnits.contains(_unitController.text)
                                    ? _unitController.text
                                    : _suggestedUnits.first,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                ),
                                items: _suggestedUnits
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _unitController.text = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Purchase Price per ${_packageTypeController.text} (₱) *',
                            hintText: 'e.g. 39.45',
                            prefixText: '₱ ',
                          ),
                          validator: (v) {
                            final num = double.tryParse(v ?? '');
                            if (num == null || num < 0) return 'Enter valid cost';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stock Count & Alert Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _countController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: '${_packagePlural(_packageTypeController.text)} on Hand',
                            hintText: 'e.g. 5',
                            prefixIcon: const Icon(Icons.numbers_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minAlertController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Low Stock Alert (${_packagePlural(_packageTypeController.text)})',
                            hintText: 'e.g. 2',
                            prefixIcon: const Icon(Icons.warning_amber_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Save Changes' : 'Add Item'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
