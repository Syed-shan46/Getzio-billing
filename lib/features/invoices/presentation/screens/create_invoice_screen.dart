import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:getzio_billing/features/customers/presentation/providers/customer_provider.dart';
import 'package:getzio_billing/features/customers/data/models/customer_model.dart';
import 'package:getzio_billing/features/products/presentation/providers/product_provider.dart';
import 'package:getzio_billing/features/products/data/models/product_model.dart';
import 'package:getzio_billing/features/invoices/data/models/invoice_model.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';
import '../providers/invoice_provider.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  CustomerModel? _selectedCustomer;
  final _invoiceNumberController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;

  final List<InvoiceItemModel> _items = [];
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  double _subtotal = 0.0;
  double _taxTotal = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    // Auto-generate invoice number
    final shortUuid = const Uuid().v4().substring(0, 8).toUpperCase();
    _invoiceNumberController.text = 'INV-$shortUuid';
    _dueDate = _issueDate.add(const Duration(days: 7)); // Default due date 7 days later
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
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
            title: const Text('Add Invoice Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Rate', prefixText: '₹ '),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
                  final rate = double.tryParse(priceController.text.trim()) ?? selectedProduct!.sellingPrice;
                  final taxRate = selectedProduct!.taxRate;
                  final totalItem = (qty * rate) * (1 + taxRate / 100);

                  setState(() {
                    _items.add(InvoiceItemModel(
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

  void _saveInvoice() async {
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

      await ref.read(invoiceProvider.notifier).createInvoice(
            customerId: _selectedCustomer!.id,
            invoiceNumber: _invoiceNumberController.text.trim(),
            status: 'pending',
            issueDate: _issueDate,
            dueDate: _dueDate,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  children: [
                    // --- Customer Selector ---
                    customersState.when(
                      data: (customers) {
                        return DropdownButtonFormField<CustomerModel>(
                          value: _selectedCustomer,
                          decoration: const InputDecoration(
                            labelText: 'Select Customer *',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
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
                    const SizedBox(height: 18),

                    // --- Invoice Details Card ---
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _invoiceNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Reference # *',
                                prefixIcon: Icon(Icons.tag_rounded, size: 20),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Invoice number is required' : null,
                            ),
                            const SizedBox(height: 12),
                            // Issue date selector
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: const Text('Issue Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.borderDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_issueDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
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
                                    if (_dueDate != null && _dueDate!.isBefore(_issueDate)) {
                                      _dueDate = _issueDate.add(const Duration(days: 7));
                                    }
                                  });
                                }
                              },
                            ),
                            const Divider(height: 16, thickness: 0.5),
                            // Due date selector
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.borderDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _dueDate != null ? DateFormat('dd MMM yyyy').format(_dueDate!) : 'Not Set',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate ?? _issueDate,
                                  firstDate: _issueDate,
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _dueDate = picked);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Items Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Line Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- Items List ---
                    if (_items.isEmpty)
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 28),
                              const SizedBox(height: 8),
                              const Text(
                                'No items added yet',
                                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Qty: ${item.quantity} × ${currencyFormat.format(item.unitPrice)} (${item.taxRate}% GST)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyFormat.format(item.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
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
                    const SizedBox(height: 24),

                    // --- Financials & Summary ---
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(_subtotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tax Total',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(_taxTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _discountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Discount Amount',
                                prefixText: '₹ ',
                              ),
                              onChanged: (val) => _calculateTotals(),
                            ),
                            const Divider(height: 28, thickness: 0.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                        labelText: 'Remarks / Notes for client',
                        prefixIcon: Icon(Icons.notes, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Persistent Action Bottom Block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveInvoice,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Save & Issue Invoice'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
