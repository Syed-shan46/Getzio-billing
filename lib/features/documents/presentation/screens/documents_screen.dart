import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:getzio_billing/features/documents/data/models/document_model.dart';
import 'package:getzio_billing/features/documents/presentation/providers/document_provider.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';
import 'create_document_screen.dart';
import 'document_details_sheet.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final Map<String, List<String>> _categories = {
    'all': ['All Documents', 'all'],
    'sales': ['Sales', 'invoice', 'gst_invoice', 'tax_invoice', 'retail_invoice', 'proforma_invoice', 'quotation', 'estimate', 'sales_order', 'delivery_challan', 'receipt', 'credit_note', 'debit_note'],
    'purchase': ['Purchase', 'purchase_order', 'purchase_invoice', 'vendor_credit_note', 'goods_received_note'],
    'inventory': ['Inventory', 'stock_transfer', 'stock_adjustment', 'material_issue_note', 'material_receipt_note'],
    'export': ['Export', 'commercial_invoice', 'packing_list', 'certificate_of_origin', 'shipping_mark_sheet', 'export_declaration'],
    'service': ['Service', 'work_order', 'job_card', 'service_report', 'completion_certificate', 'amc_contract'],
    'finance': ['Finance', 'payment_voucher', 'receipt_voucher', 'expense_voucher', 'journal_voucher'],
    'hr': ['HR', 'offer_letter', 'appointment_letter', 'salary_certificate', 'experience_letter', 'relieving_letter'],
    'legal': ['Legal', 'nda', 'agreement', 'contract', 'purchase_agreement', 'terms_conditions']
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDocumentTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Select Document Type to Create',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: _categories.entries.where((e) => e.key != 'all').map((e) {
                  final label = e.value.first;
                  final types = e.value.sublist(1);

                  return ExpansionTile(
                    title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: types.map((type) {
                      final labelStr = type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                      return ListTile(
                        title: Text(labelStr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateDocumentScreen(initialType: type),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
            onPressed: _showDocumentTypePicker,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Analytics metrics row
            documentsState.when(
              data: (docs) {
                final drafts = docs.where((d) => d.status == 'draft').length;
                final underReview = docs.where((d) => d.status == 'under_review').length;
                final approved = docs.where((d) => d.status == 'approved' || d.status == 'completed').length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetricCard('Drafts', drafts, Colors.blueGrey, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard('Reviewing', underReview, Colors.amber, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard('Approved', approved, Colors.green, isDark)),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox(),
            ),

            // Categories horizontal slider
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _categories.entries.map((e) {
                  final key = e.key;
                  final label = e.value.first;
                  final isSelected = key == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedCategory = key),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search documents, reference #, or clients...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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
              child: RefreshIndicator(
                onRefresh: () => ref.read(documentProvider.notifier).refresh(),
                child: documentsState.when(
                  data: (documents) {
                    final filtered = _filterDocuments(documents);
                    if (filtered.isEmpty) {
                      return _buildEmptyState(isDark);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        return _buildDocumentCard(doc, currencyFormat, isDark);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading documents: $err')),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          )
        ],
      ),
    );
  }

  List<DocumentModel> _filterDocuments(List<DocumentModel> docs) {
    var result = docs;
    if (_selectedCategory != 'all') {
      final allowedTypes = _categories[_selectedCategory]!.sublist(1);
      result = result.where((d) => allowedTypes.contains(d.documentType)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((d) {
        return d.documentNumber.toLowerCase().contains(_searchQuery) ||
            (d.customerObject?.name ?? '').toLowerCase().contains(_searchQuery);
      }).toList();
    }
    return result;
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                'No Documents Found',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(DocumentModel doc, NumberFormat currencyFormat, bool isDark) {
    Color statusColor;
    switch (doc.status.toLowerCase()) {
      case 'paid':
      case 'approved':
      case 'completed':
        statusColor = const Color(0xFF10B981);
        break;
      case 'under_review':
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      case 'draft':
      default:
        statusColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DocumentDetailsSheet(document: doc),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${doc.documentTypeLabel} #${doc.documentNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      doc.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.customerObject?.name ?? 'Internal Document',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Issued: ${DateFormat('dd MMM yyyy').format(doc.issueDate)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    doc.items.isEmpty ? 'N/A' : currencyFormat.format(doc.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
