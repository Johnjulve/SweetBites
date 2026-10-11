import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';

/// A widget for selecting an existing customer or creating a new one inline.
class CustomerSelector extends StatefulWidget {
  final void Function(Customer customer) onCustomerSelected;
  final Customer? selectedCustomer;

  const CustomerSelector({
    super.key,
    required this.onCustomerSelected,
    this.selectedCustomer,
  });

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Customer> _searchResults = [];
  List<Customer> _allCustomers = [];
  bool _isSearching = false;
  bool _showAllCustomers = false;
  bool _isLoadingAll = false;
  bool _showNewForm = false;
  Customer? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCustomer;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _toggleShowAllCustomers() async {
    if (_showAllCustomers) {
      setState(() {
        _showAllCustomers = false;
      });
      return;
    }

    setState(() {
      _isLoadingAll = true;
      _showAllCustomers = true;
      _showNewForm = false;
    });

    try {
      final repo = Provider.of<CustomerRepository>(context, listen: false);
      final customers = await repo.getAll();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _isLoadingAll = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAll = false);
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final repo = Provider.of<CustomerRepository>(context, listen: false);
      final results = await repo.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selected = customer;
      _searchResults = [];
      _allCustomers = [];
      _showAllCustomers = false;
      _searchController.clear();
      _showNewForm = false;
    });
    widget.onCustomerSelected(customer);
  }

  Future<void> _createAndSelect() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) return;

    final customer = Customer(name: name, phone: phone);

    try {
      final repo = Provider.of<CustomerRepository>(context, listen: false);
      await repo.insert(customer);
      _nameController.clear();
      _phoneController.clear();
      _selectCustomer(customer);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating customer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Selected customer display
        if (_selected != null && !_showNewForm) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF047857).withValues(alpha: 0.18)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (_selected!.phone.isNotEmpty)
                        Text(
                          _selected!.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _selected = null);
                  },
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Change customer',
                ),
              ],
            ),
          ),
        ] else ...[
          // Search field with contacts browser icon
          TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search customer by name or phone...',
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Clear search',
                    ),
                  IconButton(
                    onPressed: _toggleShowAllCustomers,
                    icon: Icon(
                      _showAllCustomers
                          ? Icons.contacts
                          : Icons.contacts_outlined,
                      color: _showAllCustomers
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      size: 22,
                    ),
                    tooltip: _showAllCustomers
                        ? 'Hide saved customers'
                        : 'View saved customers',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isSearching || _isLoadingAll)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          // Customer list (Search results or Browse all saved)
          if ((_searchController.text.isNotEmpty ? _searchResults : (_showAllCustomers ? _allCustomers : [])).isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF382F28) : const Color(0xFFE8DFD6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: isDark ? const Color(0xFF241F1B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showAllCustomers && _searchController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved Customers (${_allCustomers.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _showAllCustomers = false),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppTheme.textHintOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: (_searchController.text.isNotEmpty ? _searchResults : _allCustomers).length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF382F28) : const Color(0xFFE8DFD6),
                        ),
                        itemBuilder: (context, index) {
                          final c = (_searchController.text.isNotEmpty ? _searchResults : _allCustomers)[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isDark
                                  ? const Color(0xFF2E2722)
                                  : const Color(0xFFF5F0EB),
                              child: Text(
                                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE8734A),
                                ),
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: c.phone.isNotEmpty
                                ? Text(
                                    c.phone,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFB5A496)
                                          : const Color(0xFF7A6B5D),
                                    ),
                                  )
                                : null,
                            onTap: () => _selectCustomer(c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_showAllCustomers && !_isLoadingAll && _searchController.text.isEmpty && _allCustomers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                'No saved customers yet. Tap New Customer below to add one.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHintOf(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 10),

          // New Customer toggle
          if (!_showNewForm)
            TextButton.icon(
              onPressed: () => setState(() => _showNewForm = true),
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('New Customer'),
            ),

          // New Customer form
          if (_showNewForm)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF241F1B) : const Color(0xFFF5F0EB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF382F28) : const Color(0xFFE8DFD6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Customer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showNewForm = false),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Customer name *',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2E2722) : Colors.white,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2E2722) : Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nameController.text.trim().isNotEmpty
                          ? _createAndSelect
                          : null,
                      child: const Text('Add Customer'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
