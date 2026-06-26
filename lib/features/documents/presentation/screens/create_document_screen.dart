import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:getzio_billing/features/customers/presentation/providers/customer_provider.dart';
import 'package:getzio_billing/features/customers/data/models/customer_model.dart';
import 'package:getzio_billing/features/products/presentation/providers/product_provider.dart';
import 'package:getzio_billing/features/products/data/models/product_model.dart';
import 'package:getzio_billing/features/documents/data/models/document_model.dart';
import 'package:getzio_billing/features/documents/presentation/providers/document_provider.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';

class CreateDocumentScreen extends ConsumerStatefulWidget {
  final String initialType;
  const CreateDocumentScreen({super.key, this.initialType = 'invoice'});

  @override
  ConsumerState<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends ConsumerState<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _documentType;
  CustomerModel? _selectedCustomer;
  final _docNumberController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _validUntil;

  // Billing and Shipping Addresses
  final _billingStreetController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingZipController = TextEditingController();

  final _shippingStreetController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingZipController = TextEditingController();

  // Shipment Details
  final _carrierController = TextEditingController();
  final _trackingController = TextEditingController();
  final _loadingPortController = TextEditingController();
  final _dischargePortController = TextEditingController();
  final _vesselController = TextEditingController();

  // Line items
  final List<DocumentItemModel> _items = [];
  final _discountController = TextEditingController(text: '0');
  final _shippingChargesController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _internalNotesController = TextEditingController();
  final _termsController = TextEditingController();

  double _subtotal = 0.0;
  double _taxTotal = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _documentType = widget.initialType;
    _regenerateDocNumber();
    _dueDate = _issueDate.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingZipController.dispose();
    _shippingStreetController.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingZipController.dispose();
    _carrierController.dispose();
    _trackingController.dispose();
    _loadingPortController.dispose();
    _dischargePortController.dispose();
    _vesselController.dispose();
    _discountController.dispose();
    _shippingChargesController.dispose();
    _notesController.dispose();
    _internalNotesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _regenerateDocNumber() {
    String prefix = 'DOC-';
    switch (_documentType) {
      case 'invoice':
      case 'gst_invoice':
      case 'tax_invoice':
      case 'retail_invoice':
        prefix = 'INV-';
        break;
      case 'proforma_invoice':
        prefix = 'PRO-';
        break;
      case 'quotation':
        prefix = 'QT-';
        break;
      case 'estimate':
        prefix = 'EST-';
        break;
      case 'purchase_order':
        prefix = 'PO-';
        break;
      case 'delivery_challan':
        prefix = 'DC-';
        break;
      case 'receipt':
        prefix = 'REC-';
        break;
      case 'credit_note':
        prefix = 'CR-';
        break;
      case 'debit_note':
        prefix = 'DR-';
        break;
      case 'stock_transfer':
        prefix = 'ST-';
        break;
      case 'stock_adjustment':
        prefix = 'SA-';
        break;
      case 'work_order':
        prefix = 'WO-';
        break;
      case 'offer_letter':
        prefix = 'OL-';
        break;
      case 'appointment_letter':
        prefix = 'AL-';
        break;
      case 'nda':
        prefix = 'NDA-';
        break;
    }
    final shortUuid = const Uuid().v4().substring(0, 8).toUpperCase();
    _docNumberController.text = '$prefix$shortUuid';
  }

  void _calculateTotals() {
    double sub = 0.0;
    double tax = 0.0;

    for (var item in _items) {
      final itemSub = item.quantity * item.unitPrice - item.discount;
      final itemTax = itemSub * (item.taxRate / 100);
      sub += itemSub;
      tax += itemTax;
    }

    final discountGlobal = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final shippingGlobal = double.tryParse(_shippingChargesController.text.trim()) ?? 0.0;

    setState(() {
      _subtotal = sub;
      _taxTotal = tax;
      _total = (sub + tax + shippingGlobal) - discountGlobal;
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
      final discountController = TextEditingController(text: '0');

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Add Line Item'),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Item Discount (Optional)', prefixText: '₹ '),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
                  final rate = double.tryParse(priceController.text.trim()) ?? selectedProduct!.sellingPrice;
                  final discount = double.tryParse(discountController.text.trim()) ?? 0.0;
                  final taxRate = selectedProduct!.taxRate;
                  final subTotalItem = (qty * rate) - discount;
                  final taxAmount = subTotalItem * (taxRate / 100);
                  final totalItem = subTotalItem + taxAmount;

                  setState(() {
                    _items.add(DocumentItemModel(
                      productId: selectedProduct!.id,
                      name: selectedProduct!.name,
                      description: selectedProduct!.description,
                      quantity: qty,
                      unitPrice: rate,
                      discount: discount,
                      taxRate: taxRate,
                      taxAmount: taxAmount,
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

  void _saveDocument() async {
    if (_formKey.currentState!.validate()) {
      final isItemBased = ['invoice', 'gst_invoice', 'tax_invoice', 'retail_invoice', 'proforma_invoice', 'quotation', 'estimate', 'purchase_order', 'delivery_challan', 'receipt', 'credit_note', 'debit_note', 'stock_transfer', 'stock_adjustment', 'material_issue_note', 'material_receipt_note'].contains(_documentType);

      if (isItemBased && _items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one line item')),
        );
        return;
      }

      final discountGlobal = double.tryParse(_discountController.text.trim()) ?? 0.0;
      final shippingGlobal = double.tryParse(_shippingChargesController.text.trim()) ?? 0.0;

      // Extract custom field metadata
      Map<String, String> metaMap = {};

      try {
        await ref.read(documentProvider.notifier).createDocument(
              documentType: _documentType,
              customerId: _selectedCustomer?.id,
              status: 'draft',
              issueDate: _issueDate,
              dueDate: _dueDate,
              validUntil: _validUntil,
              billingAddress: AddressModel(
                street: _billingStreetController.text.trim(),
                city: _billingCityController.text.trim(),
                state: _billingStateController.text.trim(),
                zipCode: _billingZipController.text.trim(),
              ),
              shippingAddress: AddressModel(
                street: _shippingStreetController.text.trim(),
                city: _shippingCityController.text.trim(),
                state: _shippingStateController.text.trim(),
                zipCode: _shippingZipController.text.trim(),
              ),
              shipmentDetails: ShipmentDetailsModel(
                carrier: _carrierController.text.trim(),
                trackingNumber: _trackingController.text.trim(),
                portOfLoading: _loadingPortController.text.trim(),
                portOfDischarge: _dischargePortController.text.trim(),
                vesselName: _vesselController.text.trim(),
              ),
              items: _items,
              subtotal: _subtotal,
              taxTotal: _taxTotal,
              discount: discountGlobal,
              shippingCharges: shippingGlobal,
              total: _total,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              internalNotes: _internalNotesController.text.trim().isEmpty ? null : _internalNotesController.text.trim(),
              terms: _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
              metadata: metaMap,
              documentNumber: _docNumberController.text.trim(),
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_documentType.toUpperCase()} created successfully!')),
          );
        }
      } catch (e) {
        // Handled in provider state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customerProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSalesOrPurchase = ['invoice', 'gst_invoice', 'tax_invoice', 'retail_invoice', 'proforma_invoice', 'quotation', 'estimate', 'purchase_order', 'delivery_challan', 'receipt', 'credit_note', 'debit_note'].contains(_documentType);
    final isExport = ['commercial_invoice', 'packing_list', 'certificate_of_origin', 'shipping_mark_sheet', 'export_declaration'].contains(_documentType);
    final isHR = ['offer_letter', 'appointment_letter', 'salary_certificate', 'experience_letter', 'relieving_letter'].contains(_documentType);
    final isLegal = ['nda', 'agreement', 'contract', 'purchase_agreement', 'terms_conditions'].contains(_documentType);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create ${_documentType.replaceAll('_', ' ').toUpperCase()}'),
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
                    // Document Number Details card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _docNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Document Reference # *',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Document number is required' : null,
                          ),
                          const SizedBox(height: 14),
                          // Issue date row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Issue Date', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _issueDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) setState(() => _issueDate = picked);
                                },
                                child: Text(DateFormat('dd MMM yyyy').format(_issueDate)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Customer Selection if Sales or Export or Legal
                    if (isSalesOrPurchase || isExport || isLegal) ...[
                      customersState.when(
                        data: (customers) => DropdownButtonFormField<CustomerModel>(
                          value: _selectedCustomer,
                          decoration: const InputDecoration(labelText: 'Select Customer / Recipient *'),
                          items: customers.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.name));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCustomer = val),
                          validator: (val) => val == null ? 'Selection is required' : null,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err'),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Dynamic Fields: Export Shipment details
                    if (isExport) ...[
                      const Text('Export Logistics Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      TextFormField(controller: _carrierController, decoration: const InputDecoration(labelText: 'Carrier Name')),
                      const SizedBox(height: 10),
                      TextFormField(controller: _trackingController, decoration: const InputDecoration(labelText: 'Tracking / Container No')),
                      const SizedBox(height: 10),
                      TextFormField(controller: _loadingPortController, decoration: const InputDecoration(labelText: 'Port of Loading')),
                      const SizedBox(height: 10),
                      TextFormField(controller: _dischargePortController, decoration: const InputDecoration(labelText: 'Port of Discharge')),
                      const SizedBox(height: 18),
                    ],

                    // Dynamic Fields: Line items calculation (Sales, Purchase, Export, Inventory)
                    if (isSalesOrPurchase || isExport || _documentType.startsWith('stock_') || _documentType.startsWith('material_')) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Document Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Add Line Item'),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_items.isEmpty)
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('No items added yet', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ..._items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('Qty: ${item.quantity} × ${currencyFormat.format(item.unitPrice)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _items.removeAt(idx));
                                _calculateTotals();
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 18),
                    ],

                    // Totals Calculations Card
                    if (isSalesOrPurchase || isExport) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
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
                              decoration: const InputDecoration(labelText: 'Discount'),
                              onChanged: (_) => _calculateTotals(),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _shippingChargesController,
                              decoration: const InputDecoration(labelText: 'Shipping Charges'),
                              onChanged: (_) => _calculateTotals(),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(currencyFormat.format(_total), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Dynamic Fields: HR / Legal templates (Offer letter details, NDA text)
                    if (isHR || isLegal) ...[
                      const Text('Template Document Body Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Custom Letter Content Details (Optional)',
                          hintText: 'Enter dynamic letter details, candidate names, roles, NDA statements...',
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      // Regular Notes
                      TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)')),
                      const SizedBox(height: 10),
                      TextFormField(controller: _termsController, decoration: const InputDecoration(labelText: 'Terms & Conditions (Optional)')),
                    ],
                  ],
                ),
              ),

              // Action button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveDocument,
                  child: const Text('Save & Issue Draft'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
