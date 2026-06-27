import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:getzio_billing/features/company/presentation/providers/company_provider.dart';
import 'package:getzio_billing/features/documents/data/models/document_model.dart';
import 'package:getzio_billing/features/documents/presentation/providers/document_provider.dart';
import 'package:getzio_billing/features/documents/utils/pdf_generator.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';

class DocumentDetailsSheet extends ConsumerStatefulWidget {
  final DocumentModel document;

  const DocumentDetailsSheet({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailsSheet> createState() => _DocumentDetailsSheetState();
}

class _DocumentDetailsSheetState extends ConsumerState<DocumentDetailsSheet> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  late String _selectedTemplate;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.document.templateId;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf({bool isShare = false}) async {
    final company = ref.read(companyProvider).value;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your Business Profile first')),
      );
      return;
    }

    _showLoading();
    try {
      final doc = await DocumentPdfGenerator.generate(
        widget.document,
        company,
        templateOverride: _selectedTemplate,
      );

      final pdfBytes = await doc.save();
      final docName = '${widget.document.documentTypePrefix}_${widget.document.documentNumber}.pdf';

      if (mounted) _hideLoading();

      if (isShare) {
        await Printing.sharePdf(bytes: pdfBytes, filename: docName);
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: docName,
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Center(
          child: Container(
            width: 180,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Generating PDF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your document is being prepared…',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoading() {
    Navigator.of(context).pop();
  }

  void _convertToInvoice() async {
    final doc = widget.document;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text(
          'Are you sure you want to convert this ${doc.documentTypeLabel} (#${doc.documentNumber}) '
          'into a live Tax Invoice? This will copy all line items and customer records.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(documentProvider.notifier).convertDocument(doc.id);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${doc.documentTypeLabel} converted to Invoice successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument() async {
    final doc = widget.document;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete ${doc.documentTypeLabel} #${doc.documentNumber}? '
          'This action is irreversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref.read(documentProvider.notifier).deleteDocument(doc.id);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${doc.documentTypeLabel} deleted successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateDocument() async {
    final doc = widget.document;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Document'),
        content: Text(
          'Are you sure you want to duplicate this ${doc.documentTypeLabel} (#${doc.documentNumber})? '
          'This will create a new draft copy copying all details.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(documentProvider.notifier).duplicateDocument(doc.id);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${doc.documentTypeLabel} duplicated successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _requestApproval() async {
    try {
      await ref.read(documentProvider.notifier).requestApproval(widget.document.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approval requested successfully!')),
        );
      }
    } catch (_) {}
  }

  void _approveDocument() async {
    try {
      await ref.read(documentProvider.notifier).approveDocument(widget.document.id, 'Approved via Getzio Desk App');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document approved!')),
        );
      }
    } catch (_) {}
  }

  void _rejectDocument() async {
    try {
      await ref.read(documentProvider.notifier).rejectDocument(widget.document.id, 'Rejected via Getzio Desk App');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document rejected!')),
        );
      }
    } catch (_) {}
  }

  void _showShareDesignPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? AppColors.backgroundDark : Colors.white;
            final textCol = isDark ? Colors.white : AppColors.textPrimaryLight;
            final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

            final templates = [
              {'id': 'modern', 'name': 'Modern Bold', 'desc': 'Clean, dark headers, professional', 'icon': Icons.space_dashboard_outlined, 'color': Colors.indigo},
              {'id': 'classic', 'name': 'Classic Serif', 'desc': 'Traditional layout with subtle borders', 'icon': Icons.description_outlined, 'color': Colors.brown},
              {'id': 'corporate', 'name': 'Corporate Pro', 'desc': 'Grid alignment, detailed headers', 'icon': Icons.business_outlined, 'color': Colors.blueGrey},
              {'id': 'minimal', 'name': 'Minimalist', 'desc': 'Ultra light, plenty of negative space', 'icon': Icons.notes_outlined, 'color': Colors.grey},
            ];

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderCol.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Design Theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the layout template to share this document.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...templates.map((temp) {
                      final isSelected = _selectedTemplate == temp['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              _selectedTemplate = temp['id'] as String;
                            });
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (temp['color'] as Color).withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? (temp['color'] as Color)
                                    : borderCol,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (temp['color'] as Color).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    temp['icon'] as IconData,
                                    color: temp['color'] as Color,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        temp['name'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: textCol,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        temp['desc'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: temp['color'] as Color,
                                  )
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _generatePdf(isShare: true);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final clientName = doc.customerObject?.name ?? 'Internal Document';
    final clientPhone = doc.customerObject?.phone ?? 'No contact';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canConvert = ['quotation', 'estimate', 'purchase_order'].contains(doc.documentType) &&
        doc.status.toLowerCase() != 'invoiced' &&
        doc.status.toLowerCase() != 'converted' &&
        doc.status.toLowerCase() != 'completed';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      height: MediaQuery.of(context).size.height * 0.88,
      child: SafeArea(
        top: false,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${doc.documentTypeLabel} Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${doc.documentNumber} | Version v${doc.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
          const SizedBox(height: 18),

          Expanded(
            child: ListView(
              children: [
                // Workflow actions row if status is draft or reviewing
                if (doc.status == 'draft') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _requestApproval,
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Submit for Review'),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (doc.status == 'under_review') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: _rejectDocument,
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _approveDocument,
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Customer info
                if (doc.customer != null) ...[
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECIPIENT / CLIENT',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              const SizedBox(width: 6),
                              Text(
                                'Phone: $clientPhone',
                                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Line items list
                if (doc.items.isNotEmpty) ...[
                  Text(
                    'ITEMS & DETAILS',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...doc.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity} × ${currencyFormat.format(item.unitPrice)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.total),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],

                // Totals Calculations Card
                if (doc.items.isNotEmpty) ...[
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
                          _buildSummaryRow('Subtotal', currencyFormat.format(doc.subtotal)),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Taxes Total', currencyFormat.format(doc.taxTotal)),
                          if (doc.discount > 0) ...[
                            const SizedBox(height: 8),
                            _buildSummaryRow('Discount', '- ${currencyFormat.format(doc.discount)}', isDiscount: true),
                          ],
                          if (doc.shippingCharges > 0) ...[
                            const SizedBox(height: 8),
                            _buildSummaryRow('Shipping', currencyFormat.format(doc.shippingCharges)),
                          ],
                          const Divider(height: 24, thickness: 0.5),
                          _buildSummaryRow('Grand Total', currencyFormat.format(doc.total), isBold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Letter Content if HR / Legal
                if (doc.notes != null && doc.notes!.isNotEmpty && doc.items.isEmpty) ...[
                  Text(
                    'DOCUMENT CONTENT',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      doc.notes!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),

          // Action icons row
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionIcon(
                icon: Icons.share,
                label: 'Share',
                onTap: () => _showShareDesignPicker(context),
              ),
              _ActionIcon(
                icon: Icons.print,
                label: 'Print',
                onTap: () => _generatePdf(isShare: false),
              ),
              if (canConvert)
                _ActionIcon(
                  icon: Icons.transform,
                  label: 'Convert',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: _convertToInvoice,
                ),
              _ActionIcon(
                icon: Icons.copy,
                label: 'Duplicate',
                onTap: _duplicateDocument,
              ),
              _ActionIcon(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Theme.of(context).colorScheme.error,
                onTap: _deleteDocument,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      fontSize: isBold ? 15 : 13,
      color: isDiscount
          ? const Color(0xFF10B981)
          : isBold
              ? (isDark ? Colors.white : AppColors.textPrimaryLight)
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? Colors.white : const Color(0xFF374151));
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
