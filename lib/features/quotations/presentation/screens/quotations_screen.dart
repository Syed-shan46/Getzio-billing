import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:getzio_billing/features/quotations/data/models/quotation_model.dart';
import 'package:getzio_billing/features/company/presentation/providers/company_provider.dart';
import 'package:getzio_billing/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:getzio_billing/features/invoices/data/models/invoice_model.dart';
import '../providers/quotation_provider.dart';
import 'create_quotation_screen.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotationsState = ref.watch(quotationProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimates & Quotations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateQuotationScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Draft'),
            Tab(text: 'Accepted'),
            Tab(text: 'Invoiced'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search estimate # or customer...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            Expanded(
              child: quotationsState.when(
                data: (quotations) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQuotationList(quotations, 'all', currencyFormat),
                      _buildQuotationList(quotations, 'draft', currencyFormat),
                      _buildQuotationList(quotations, 'accepted', currencyFormat),
                      _buildQuotationList(quotations, 'invoiced', currencyFormat),
                      _buildQuotationList(quotations, 'rejected', currencyFormat),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error loading quotations: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationList(List<QuotationModel> quotations, String filterStatus, NumberFormat currencyFormat) {
    var filtered = quotations;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((q) {
        final numMatch = q.quotationNumber.toLowerCase().contains(_searchQuery);
        final custMatch = (q.customerObject?.name ?? '').toLowerCase().contains(_searchQuery);
        return numMatch || custMatch;
      }).toList();
    }

    // Status tab filter
    if (filterStatus != 'all') {
      filtered = filtered.where((q) => q.status.toLowerCase() == filterStatus).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.request_quote_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No Quotations Found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final quotation = filtered[index];
        return _buildQuotationCard(quotation, currencyFormat);
      },
    );
  }

  Widget _buildQuotationCard(QuotationModel quotation, NumberFormat currencyFormat) {
    Color statusColor;
    switch (quotation.status) {
      case 'accepted':
      case 'invoiced':
        statusColor = const Color(0xFF34C759);
        break;
      case 'draft':
      case 'sent':
        statusColor = const Color(0xFFFFCC00);
        break;
      case 'rejected':
        statusColor = const Color(0xFFFF3B30);
        break;
      default:
        statusColor = const Color(0xFF8E8E93);
    }

    final String clientName = quotation.customerObject?.name ?? 'Unknown Customer';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewQuotationDetails(quotation),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimate #${quotation.quotationNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quotation.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                clientName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expires: ${DateFormat('dd MMM yyyy').format(quotation.expiryDate ?? quotation.issueDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                  Text(
                    currencyFormat.format(quotation.total),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewQuotationDetails(QuotationModel quotation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuotationDetailsSheet(quotation: quotation),
    );
  }
}

class _QuotationDetailsSheet extends ConsumerStatefulWidget {
  final QuotationModel quotation;

  const _QuotationDetailsSheet({required this.quotation});

  @override
  ConsumerState<_QuotationDetailsSheet> createState() => _QuotationDetailsSheetState();
}

class _QuotationDetailsSheetState extends ConsumerState<_QuotationDetailsSheet> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  Future<void> _generatePdf() async {
    final company = ref.read(companyProvider).value;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your Business Profile first')),
      );
      return;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header (Company Details)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(company.companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        if (company.gstNumber != null) pw.Text('GSTIN: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 10)),
                        if (company.phone != null) pw.Text('Phone: ${company.phone}', style: const pw.TextStyle(fontSize: 10)),
                        if (company.email != null) pw.Text('Email: ${company.email}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('PROFORMA ESTIMATE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.Text('Estimate #: ${widget.quotation.quotationNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(widget.quotation.issueDate)}'),
                        if (widget.quotation.expiryDate != null) pw.Text('Expiry Date: ${DateFormat('dd-MM-yyyy').format(widget.quotation.expiryDate!)}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, height: 30),

                // Bill To Details
                pw.Text('ESTIMATE FOR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(widget.quotation.customerObject?.name ?? 'Customer Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                if (widget.quotation.customerObject?.phone != null) pw.Text('Phone: ${widget.quotation.customerObject!.phone}'),
                if (widget.quotation.customerObject?.email != null) pw.Text('Email: ${widget.quotation.customerObject!.email}'),
                if (widget.quotation.customerObject?.gstNumber != null) pw.Text('GSTIN: ${widget.quotation.customerObject!.gstNumber}'),
                pw.SizedBox(height: 24),

                // Items Table
                pw.Table(
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                    bottom: pw.BorderSide(width: 1.0, color: PdfColors.grey500),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.2),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item / Service', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tax %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...widget.quotation.items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.name)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.quantity.toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.unitPrice.toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.taxRate}%')),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.total.toString())),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Quotation Summary Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (widget.quotation.notes != null) ...[
                          pw.Text('TERMS & NOTES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey700)),
                          pw.Container(width: 250, child: pw.Text(widget.quotation.notes!, style: const pw.TextStyle(fontSize: 8))),
                        ],
                      ],
                    ),
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:'),
                              pw.Text('INR ${widget.quotation.subtotal}'),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Tax Total:'),
                              pw.Text('INR ${widget.quotation.taxTotal}'),
                            ],
                          ),
                          if (widget.quotation.discount > 0)
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Discount:'),
                                pw.Text('- INR ${widget.quotation.discount}'),
                              ],
                            ),
                          pw.Divider(thickness: 1),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Estimate Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                              pw.Text('INR ${widget.quotation.total}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Signatures
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('For ${company.companyName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(width: 0.5, color: PdfColors.grey500),
                          ),
                        ),
                      ),
                      pw.Text('Authorized Representative', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'estimate_${widget.quotation.quotationNumber}.pdf',
    );
  }

  void _convertToInvoice() async {
    final q = widget.quotation;
    final shortUuid = const Uuid().v4().substring(0, 8).toUpperCase();
    final newInvNumber = 'INV-$shortUuid';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text('Are you sure you want to convert Estimate #${q.quotationNumber} into a live Tax Invoice with invoice number $newInvNumber?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Convert items to Invoice items
              final invItems = q.items.map((qi) {
                return InvoiceItemModel(
                  productId: qi.productId,
                  name: qi.name,
                  description: qi.description,
                  quantity: qi.quantity,
                  unitPrice: qi.unitPrice,
                  taxRate: qi.taxRate,
                  total: qi.total,
                );
              }).toList();

              // Create invoice via Provider
              await ref.read(invoiceProvider.notifier).createInvoice(
                    customerId: q.customerId,
                    invoiceNumber: newInvNumber,
                    status: 'pending',
                    issueDate: DateTime.now(),
                    dueDate: DateTime.now().add(const Duration(days: 7)),
                    items: invItems,
                    subtotal: q.subtotal,
                    taxTotal: q.taxTotal,
                    discount: q.discount,
                    total: q.total,
                    notes: q.notes,
                    terms: q.terms,
                  );

              // Find newly created invoice id in invoices list or use fallback. Since we refreshed invoices, we can query it or simply complete the flow.
              // Update Quotation to 'invoiced'
              await ref.read(quotationProvider.notifier).updateQuotation(
                    id: q.id,
                    customerId: q.customerId,
                    quotationNumber: q.quotationNumber,
                    status: 'invoiced',
                    issueDate: q.issueDate,
                    expiryDate: q.expiryDate,
                    items: q.items,
                    subtotal: q.subtotal,
                    taxTotal: q.taxTotal,
                    discount: q.discount,
                    total: q.total,
                    notes: q.notes,
                    terms: q.terms,
                    convertedInvoiceId: 'CONVERTED', // Placeholder, backend handles or updates
                  );

              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Quotation converted to Invoice $newInvNumber successfully!')),
              );
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quotation;
    final clientName = q.customerObject?.name ?? 'Unknown Customer';
    final clientPhone = q.customerObject?.phone ?? 'No contact';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimate #${q.quotationNumber}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                // Client details
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTIMATE FOR',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text('Phone: $clientPhone', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        if (q.customerObject?.gstNumber != null) ...[
                          const SizedBox(height: 4),
                          Text('GST: ${q.customerObject!.gstNumber}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items list
                const Text(
                  'ESTIMATE ITEMS',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...q.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('Qty: ${item.quantity} × ${currencyFormat.format(item.unitPrice)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Text(currencyFormat.format(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),

                // Financial details
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', currencyFormat.format(q.subtotal)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax Total', currencyFormat.format(q.taxTotal)),
                        if (q.discount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow('Discount', '- ${currencyFormat.format(q.discount)}', isDiscount: true),
                        ],
                        const Divider(height: 24),
                        _buildSummaryRow('Estimate Total', currencyFormat.format(q.total), isBold: true),
                      ],
                    ),
                  ),
                ),
                if (q.notes != null && q.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('TERMS & CONDITIONS', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(q.notes!, style: const TextStyle(fontSize: 14)),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print / PDF'),
                ),
              ),
              const SizedBox(width: 12),
              if (q.status != 'invoiced')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _convertToInvoice,
                    icon: const Icon(Icons.transform),
                    label: const Text('Convert to Invoice'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 16 : 14,
      color: isDiscount ? Colors.green : null,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
