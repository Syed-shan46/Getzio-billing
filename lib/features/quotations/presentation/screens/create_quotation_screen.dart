import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:getzio_billing/features/customers/presentation/providers/customer_provider.dart';
import 'package:getzio_billing/features/customers/data/models/customer_model.dart';
import 'package:getzio_billing/features/products/presentation/providers/product_provider.dart';
import 'package:getzio_billing/features/products/data/models/product_model.dart';
import 'package:getzio_billing/features/quotations/data/models/quotation_model.dart';
import '../providers/quotation_provider.dart';

class CreateQuotationScreen extends ConsumerStatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  ConsumerState<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends ConsumerState<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _selectedCustomer;
  final _quotationNumberController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime? _expiryDate;

  final List<QuotationItemModel> _items = [];
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  double _subtotal = 0.0;
  double _taxTotal = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    final shortUuid = const Uuid().v4().substring(0, 8).toUpperCase();
    _quotationNumberController.text = 'EST-$shortUuid';
    _expiryDate = _issueDate.add(const Duration(days: 30)); // 30 days validity
  }

  @override
  void dispose() {
    _quotationNumberController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double sub = 0.0;
    double tax = 0.0;

    for (var item in _items) {
      final itemSub = item.quantity * item.unitPrice;
      final itemTax = itemSub * (item.taxRate / 100);
      sub += itemSub;
      tax += itemTax;
    }

    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    setState(() {
      _subtotal = sub;
      _taxTotal = tax;
      _total = (sub + tax) - discount;
      if (_total < 0) _total = 0.0;
    });
  }

  void _addItem() {
    final productsState = ref.read(productProvider);
    productsState.whenData((products) {
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products available. Please create products first.')),
        );
        return;
      }

      ProductModel? selectedProduct = products.first;
      final qtyController = TextEditingController(text: '1');
      final priceController = TextEditingController(text: selectedProduct.sellingPrice.toString());

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Add Estimate Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProductModel>(
                  value: selectedProduct,
                  decoration: const InputDecoration(labelText: 'Product / Service'),
                  items: products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() {
                        selectedProduct = val;
                        priceController.text = val.sellingPrice.toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Custom Rate', prefixText: '₹ '),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
                  final rate = double.tryParse(priceController.text.trim()) ?? selectedProduct!.sellingPrice;
                  final taxRate = selectedProduct!.taxRate;
                  final totalItem = (qty * rate) * (1 + taxRate / 100);

                  setState(() {
                    _items.add(QuotationItemModel(
                      productId: selectedProduct!.id,
                      name: selectedProduct!.name,
                      description: selectedProduct!.description,
                      quantity: qty,
                      unitPrice: rate,
                      taxRate: taxRate,
                      total: double.parse(totalItem.toStringAsFixed(2)),
                    ));
                  });

                  _calculateTotals();
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _saveQuotation() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }

      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

      await ref.read(quotationProvider.notifier).createQuotation(
            customerId: _selectedCustomer!.id,
            quotationNumber: _quotationNumberController.text.trim(),
            status: 'draft',
            issueDate: _issueDate,
            expiryDate: _expiryDate,
            items: _items,
            subtotal: _subtotal,
            taxTotal: _taxTotal,
            discount: discount,
            total: _total,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            terms: _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
          );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customerProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Estimate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveQuotation,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Customer Selector ---
              customersState.when(
                data: (customers) {
                  return DropdownButtonFormField<CustomerModel>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Select Customer *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: customers.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCustomer = val);
                    },
                    validator: (val) => val == null ? 'Customer is required' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading customers: $err'),
              ),
              const SizedBox(height: 16),

              // --- Est details ---
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _quotationNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Estimate Number *',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Estimate number is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Issue date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Estimate Date'),
                        trailing: Text(DateFormat('dd MMM yyyy').format(_issueDate)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _issueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _issueDate = picked;
                              if (_expiryDate != null && _expiryDate!.isBefore(_issueDate)) {
                                _expiryDate = _issueDate.add(const Duration(days: 30));
                              }
                            });
                          }
                        },
                      ),
                      const Divider(),
                      // Expiry date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Expiry Date'),
                        trailing: Text(_expiryDate != null ? DateFormat('dd MMM yyyy').format(_expiryDate!) : 'Not Set'),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? _issueDate,
                            firstDate: _issueDate,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _expiryDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Items Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Line Items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // --- Items List ---
              if (_items.isEmpty)
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: const Center(
                    child: Text('No items added yet', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ..._items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Qty: ${item.quantity} × ${currencyFormat.format(item.unitPrice)} (${item.taxRate}% tax)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(item.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              setState(() => _items.removeAt(idx));
                              _calculateTotals();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // --- Summary Details ---
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(currencyFormat.format(_subtotal)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax Total'),
                          Text(currencyFormat.format(_taxTotal)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Discount Amount (₹)',
                          prefixText: '₹ ',
                        ),
                        onChanged: (val) => _calculateTotals(),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Total',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            currencyFormat.format(_total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Remarks ---
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Terms for estimate',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveQuotation,
                child: const Text('Save and Print Estimate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
