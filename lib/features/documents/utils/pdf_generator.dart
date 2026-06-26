import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:getzio_billing/features/company/data/models/company_model.dart';
import 'package:getzio_billing/features/documents/data/models/document_model.dart';

class DocumentPdfGenerator {
  static Future<pw.Document> generate(DocumentModel document, CompanyModel company, {String? templateOverride}) async {
    final doc = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    final dateFormat = DateFormat('dd-MM-yyyy');

    // 1. Fetch images asynchronously with error catch fallback
    pw.ImageProvider? logoImage;
    if (company.logoUrl != null && company.logoUrl!.isNotEmpty) {
      try {
        logoImage = await networkImage(company.logoUrl!);
      } catch (e) {
        // Fallback silently if offline or load fails
      }
    }

    pw.ImageProvider? signatureImage;
    if (company.signatureUrl != null && company.signatureUrl!.isNotEmpty) {
      try {
        signatureImage = await networkImage(company.signatureUrl!);
      } catch (e) {
        // Fallback silently
      }
    }

    pw.ImageProvider? stampImage;
    if (company.stampUrl != null && company.stampUrl!.isNotEmpty) {
      try {
        stampImage = await networkImage(company.stampUrl!);
      } catch (e) {
        // Fallback silently
      }
    }

    // 2. Select Template Layout
    final activeTemplate = templateOverride ?? document.templateId;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          switch (activeTemplate) {
            case 'minimal':
              return _buildMinimalTemplate(document, company, logoImage, signatureImage, stampImage, currencyFormat, dateFormat);
            case 'classic':
              return _buildClassicTemplate(document, company, logoImage, signatureImage, stampImage, currencyFormat, dateFormat);
            case 'corporate':
              return _buildCorporateTemplate(document, company, logoImage, signatureImage, stampImage, currencyFormat, dateFormat);
            case 'modern':
            default:
              return _buildModernTemplate(document, company, logoImage, signatureImage, stampImage, currencyFormat, dateFormat);
          }
        },
      ),
    );

    return doc;
  }

  // --- MODERN TEMPLATE ---
  static pw.Widget _buildModernTemplate(
    DocumentModel document,
    CompanyModel company,
    pw.ImageProvider? logo,
    pw.ImageProvider? signature,
    pw.ImageProvider? stamp,
    NumberFormat cur,
    DateFormat date,
  ) {
    const accentColor = PdfColors.indigo800;
    const lightAccent = PdfColors.indigo50;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Brand Header (Logo and Document Title)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                if (logo != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company.companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: accentColor)),
                    if (company.gstNumber != null) pw.Text('GSTIN: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 9)),
                    if (company.phone != null) pw.Text('Phone: ${company.phone}', style: const pw.TextStyle(fontSize: 9)),
                    if (company.email != null) pw.Text('Email: ${company.email}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(document.documentTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: accentColor)),
                pw.Text('No: ${document.documentNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('Date: ${date.format(document.issueDate)}', style: const pw.TextStyle(fontSize: 9)),
                if (document.dueDate != null)
                  pw.Text('Due Date: ${date.format(document.dueDate!)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Parties Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightAccent,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CLIENT / BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: accentColor)),
                    pw.SizedBox(height: 4),
                    pw.Text(document.customerObject?.name ?? 'Customer Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    if (document.customerObject?.phone != null) pw.Text('Phone: ${document.customerObject!.phone}', style: const pw.TextStyle(fontSize: 9)),
                    if (document.customerObject?.email != null) pw.Text('Email: ${document.customerObject!.email}', style: const pw.TextStyle(fontSize: 9)),
                    if (document.customerObject?.gstNumber != null) pw.Text('GSTIN: ${document.customerObject!.gstNumber}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            // Shipment / Metadata Details
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DETAILS & SHIPPING:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    ...document.metadata.entries.map((entry) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(fontSize: 9),
                            children: [
                              pw.TextSpan(text: '${entry.key}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.TextSpan(text: entry.value),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    if (document.metadata.isEmpty)
                      pw.Text('Standard delivery terms apply.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Items Table
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            bottom: pw.BorderSide(width: 1.0, color: accentColor),
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
              decoration: const pw.BoxDecoration(color: accentColor),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tax %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
              ],
            ),
            ...document.items.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        if (item.description != null) pw.Text(item.description!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(cur.format(item.unitPrice), style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.taxRate}%', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(cur.format(item.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 15),

        // Summary totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (document.notes != null) ...[
                    pw.Text('TERMS & NOTES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: accentColor)),
                    pw.Container(width: 250, child: pw.Text(document.notes!, style: const pw.TextStyle(fontSize: 8))),
                  ],
                ],
              ),
            ),
            pw.Container(
              width: 180,
              child: pw.Column(
                children: [
                  _buildSummaryRow('Subtotal', cur.format(document.subtotal)),
                  _buildSummaryRow('Taxes', cur.format(document.taxTotal)),
                  if (document.discount > 0)
                    _buildSummaryRow('Discount', '- ${cur.format(document.discount)}', color: PdfColors.green),
                  pw.Divider(thickness: 1, color: accentColor),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentColor)),
                      pw.Text(cur.format(document.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Spacer(),

        // Signatures and QR Code Placeholder
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Stamp Placeholder
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (stamp != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Image(stamp, fit: pw.BoxFit.contain),
                  ),
                pw.Text('Official Stamp', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
            // QR Code Placeholder
            pw.Container(
              width: 60,
              height: 60,
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              padding: const pw.EdgeInsets.all(4),
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'Getzio Desk Doc #${document.documentNumber}',
                width: 50,
                height: 50,
              ),
            ),
            // Signature Area
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (signature != null)
                  pw.Container(
                    width: 100,
                    height: 40,
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Image(signature, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 44),
                pw.Container(width: 120, height: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),
                pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- MINIMAL TEMPLATE ---
  static pw.Widget _buildMinimalTemplate(
    DocumentModel document,
    CompanyModel company,
    pw.ImageProvider? logo,
    pw.ImageProvider? signature,
    pw.ImageProvider? stamp,
    NumberFormat cur,
    DateFormat date,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Title Block
        pw.Text(document.documentTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
        pw.Divider(thickness: 1, color: PdfColors.black),
        pw.SizedBox(height: 10),

        // Company Details & Doc Number side by side
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company.companyName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (company.phone != null) pw.Text('Ph: ${company.phone}', style: const pw.TextStyle(fontSize: 8)),
                if (company.email != null) pw.Text('Email: ${company.email}', style: const pw.TextStyle(fontSize: 8)),
                if (company.gstNumber != null) pw.Text('GSTIN: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Doc #: ${document.documentNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Issue Date: ${date.format(document.issueDate)}', style: const pw.TextStyle(fontSize: 8)),
                if (document.dueDate != null) pw.Text('Due Date: ${date.format(document.dueDate!)}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Client Details
        pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey700)),
        pw.Text(document.customerObject?.name ?? 'Customer Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        if (document.customerObject?.phone != null) pw.Text('Ph: ${document.customerObject!.phone}', style: const pw.TextStyle(fontSize: 8)),
        if (document.customerObject?.gstNumber != null) pw.Text('GSTIN: ${document.customerObject!.gstNumber}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 20),

        // Items Table (minimal design)
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            bottom: pw.BorderSide(width: 0.5, color: PdfColors.black),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
              ],
            ),
            ...document.items.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(cur.format(item.unitPrice), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(cur.format(item.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 12),

        // Summary totals
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Container(
            width: 150,
            child: pw.Column(
              children: [
                _buildSummaryRow('Subtotal', cur.format(document.subtotal)),
                _buildSummaryRow('Taxes', cur.format(document.taxTotal)),
                if (document.discount > 0) _buildSummaryRow('Discount', '- ${cur.format(document.discount)}'),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(cur.format(document.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.Spacer(),

        // Signature line (No stamps or logo in minimal clean)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (document.notes != null)
              pw.Container(
                width: 250,
                child: pw.Text('Note: ${document.notes!}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
              )
            else
              pw.SizedBox(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (signature != null)
                  pw.Container(
                    width: 80,
                    height: 30,
                    child: pw.Image(signature, fit: pw.BoxFit.contain),
                  ),
                pw.Container(width: 100, height: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Text('Authorized Person', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- CLASSIC TEMPLATE ---
  static pw.Widget _buildClassicTemplate(
    DocumentModel document,
    CompanyModel company,
    pw.ImageProvider? logo,
    pw.ImageProvider? signature,
    pw.ImageProvider? stamp,
    NumberFormat cur,
    DateFormat date,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Classic Double Line Border Header
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1, style: pw.BorderStyle.solid),
              bottom: pw.BorderSide(width: 1, style: pw.BorderStyle.solid),
            ),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(company.companyName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(document.documentTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 15),

        // Details Block
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FROM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                if (company.address.street != null) pw.Text(company.address.street!, style: const pw.TextStyle(fontSize: 8)),
                pw.Text('${company.address.city ?? ''}, ${company.address.state ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                if (company.gstNumber != null) pw.Text('GSTIN: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('DOCUMENT NO: ${document.documentNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text('DATE OF ISSUE: ${date.format(document.issueDate)}', style: const pw.TextStyle(fontSize: 8)),
                if (document.dueDate != null) pw.Text('DATE OF DUE: ${date.format(document.dueDate!)}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 0.5),

        // Bill to
        pw.Text('TO / BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text(document.customerObject?.name ?? 'Customer Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        if (document.customerObject?.email != null) pw.Text(document.customerObject!.email!, style: const pw.TextStyle(fontSize: 8)),
        if (document.customerObject?.phone != null) pw.Text('Phone: ${document.customerObject!.phone}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 15),

        // Classic Grid Table
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Unit Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
              ],
            ),
            ...document.items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(idx.toString(), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(cur.format(item.unitPrice), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(cur.format(item.total), style: const pw.TextStyle(fontSize: 8))),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 15),

        // Calculations
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (document.terms != null) ...[
                    pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text(document.terms!, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ],
              ),
            ),
            pw.Container(
              width: 180,
              child: pw.Column(
                children: [
                  _buildSummaryRow('Subtotal', cur.format(document.subtotal)),
                  _buildSummaryRow('Tax', cur.format(document.taxTotal)),
                  if (document.discount > 0) _buildSummaryRow('Discount', '- ${cur.format(document.discount)}'),
                  pw.Divider(thickness: 1),
                  // Double line for classic total representation
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(width: 0.5, style: pw.BorderStyle.solid),
                        bottom: pw.BorderSide(width: 1.5, style: pw.BorderStyle.solid),
                      ),
                    ),
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text(cur.format(document.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Spacer(),

        // Stamp and Signature
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (stamp != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(stamp, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (signature != null)
                  pw.Container(
                    width: 80,
                    height: 30,
                    child: pw.Image(signature, fit: pw.BoxFit.contain),
                  ),
                pw.Container(width: 120, height: 0.5, color: PdfColors.grey600),
                pw.SizedBox(height: 2),
                pw.Text('For ${company.companyName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- CORPORATE TEMPLATE ---
  static pw.Widget _buildCorporateTemplate(
    DocumentModel document,
    CompanyModel company,
    pw.ImageProvider? logo,
    pw.ImageProvider? signature,
    pw.ImageProvider? stamp,
    NumberFormat cur,
    DateFormat date,
  ) {
    const primary = PdfColors.teal800;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Two-column Top Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 70,
                    height: 50,
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                pw.Text(company.companyName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primary)),
                if (company.website != null) pw.Text(company.website!, style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  color: primary,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: pw.Text(document.documentTypeLabel.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Document Reference: ${document.documentNumber}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Issue Date: ${date.format(document.issueDate)}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: primary),
        pw.SizedBox(height: 15),

        // Three-column details layout (Sender, Recipient, Metadata)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company Info
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ISSUED BY:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: primary)),
                  pw.SizedBox(height: 4),
                  if (company.address.street != null) pw.Text(company.address.street!, style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('${company.address.city ?? ''}, ${company.address.state ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                  if (company.phone != null) pw.Text('Tel: ${company.phone}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            // Customer Info
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILLED TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: primary)),
                  pw.SizedBox(height: 4),
                  pw.Text(document.customerObject?.name ?? 'Customer Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  if (document.customerObject?.address.street != null) pw.Text(document.customerObject!.address.street!, style: const pw.TextStyle(fontSize: 8)),
                  if (document.customerObject?.phone != null) pw.Text('Tel: ${document.customerObject!.phone}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            // Payment info
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PAYMENT TERMS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: primary)),
                  pw.SizedBox(height: 4),
                  if (company.bankDetails.bankName != null) ...[
                    pw.Text('Bank: ${company.bankDetails.bankName}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('A/C No: ${company.bankDetails.accountNumber}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('IFSC: ${company.bankDetails.ifscCode}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Document Items Table
        pw.Table(
          border: const pw.TableBorder(
            bottom: pw.BorderSide(width: 1.5, color: primary),
          ),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: primary),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Line Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8))),
              ],
            ),
            ...document.items.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(cur.format(item.unitPrice), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(cur.format(item.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 12),

        // Financial Summary
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Container(
            width: 160,
            child: pw.Column(
              children: [
                _buildSummaryRow('Subtotal', cur.format(document.subtotal)),
                _buildSummaryRow('Taxes', cur.format(document.taxTotal)),
                if (document.discount > 0) _buildSummaryRow('Discount', '- ${cur.format(document.discount)}'),
                pw.Divider(thickness: 1, color: primary),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Due:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: primary)),
                    pw.Text(cur.format(document.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.Spacer(),

        // Stamp and Signature Side-by-Side
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                if (stamp != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(stamp, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 60),
                pw.Text('Official Corporate Stamp', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              children: [
                if (signature != null)
                  pw.Container(
                    width: 80,
                    height: 40,
                    child: pw.Image(signature, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 40),
                pw.SizedBox(height: 20),
                pw.Container(width: 120, height: 0.5, color: PdfColors.grey500),
                pw.SizedBox(height: 2),
                pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Helper helper function to build summary tables rows
  static pw.Widget _buildSummaryRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
