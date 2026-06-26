import 'package:getzio_billing/features/invoices/data/models/invoice_model.dart';

class PaymentModel {
  final String id;
  final dynamic invoice; // InvoiceModel or String
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.invoice,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    dynamic invoiceData = json['invoiceId'];
    if (invoiceData is Map<String, dynamic>) {
      invoiceData = InvoiceModel.fromJson(invoiceData);
    }

    return PaymentModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      invoice: invoiceData,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : DateTime.now(),
      paymentMethod: json['paymentMethod'] as String? ?? 'other',
      referenceNumber: json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoice is InvoiceModel ? (invoice as InvoiceModel).id : invoice,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
    };
  }

  InvoiceModel? get invoiceObject => invoice is InvoiceModel ? invoice as InvoiceModel : null;
  String get invoiceId => invoice is InvoiceModel ? (invoice as InvoiceModel).id : invoice.toString();
}
