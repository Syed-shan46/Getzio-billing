import 'package:getzio_billing/features/customers/data/models/customer_model.dart';

class QuotationItemModel {
  final String? productId;
  final String name;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double total;

  QuotationItemModel({
    this.productId,
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0.0,
    required this.total,
  });

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) {
    return QuotationItemModel(
      productId: json['productId'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'total': total,
    };
  }
}

class QuotationModel {
  final String id;
  final dynamic customer; // CustomerModel or String
  final String quotationNumber;
  final String status;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final List<QuotationItemModel> items;
  final double subtotal;
  final double taxTotal;
  final double discount;
  final double total;
  final String? notes;
  final String? terms;
  final String? convertedInvoiceId;

  QuotationModel({
    required this.id,
    required this.customer,
    required this.quotationNumber,
    required this.status,
    required this.issueDate,
    this.expiryDate,
    required this.items,
    this.subtotal = 0.0,
    this.taxTotal = 0.0,
    this.discount = 0.0,
    required this.total,
    this.notes,
    this.terms,
    this.convertedInvoiceId,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    dynamic customerData = json['customerId'];
    if (customerData is Map<String, dynamic>) {
      customerData = CustomerModel.fromJson(customerData);
    }

    return QuotationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      customer: customerData,
      quotationNumber: json['quotationNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate']) : DateTime.now(),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => QuotationItemModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      convertedInvoiceId: json['convertedInvoiceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customer is CustomerModel ? (customer as CustomerModel).id : customer,
      'quotationNumber': quotationNumber,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'taxTotal': taxTotal,
      'discount': discount,
      'total': total,
      'notes': notes,
      'terms': terms,
    };
  }

  CustomerModel? get customerObject => customer is CustomerModel ? customer as CustomerModel : null;
  String get customerId => customer is CustomerModel ? (customer as CustomerModel).id : customer.toString();
}
