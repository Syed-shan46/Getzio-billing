import 'package:getzio_billing/features/customers/data/models/customer_model.dart';

class InvoiceItemModel {
  final String? productId;
  final String name;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double total;

  InvoiceItemModel({
    this.productId,
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0.0,
    required this.total,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
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

class InvoiceModel {
  final String id;
  final dynamic customer; // Can be CustomerModel (if populated) or String (customerId)
  final String invoiceNumber;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double taxTotal;
  final double discount;
  final double total;
  final double amountPaid;
  final String? notes;
  final String? terms;

  InvoiceModel({
    required this.id,
    required this.customer,
    required this.invoiceNumber,
    required this.status,
    required this.issueDate,
    this.dueDate,
    required this.items,
    this.subtotal = 0.0,
    this.taxTotal = 0.0,
    this.discount = 0.0,
    required this.total,
    this.amountPaid = 0.0,
    this.notes,
    this.terms,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    dynamic customerData = json['customerId'];
    if (customerData is Map<String, dynamic>) {
      customerData = CustomerModel.fromJson(customerData);
    }

    return InvoiceModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      customer: customerData,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate']) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => InvoiceItemModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customer is CustomerModel ? (customer as CustomerModel).id : customer,
      'invoiceNumber': invoiceNumber,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'taxTotal': taxTotal,
      'discount': discount,
      'total': total,
      'amountPaid': amountPaid,
      'notes': notes,
      'terms': terms,
    };
  }

  CustomerModel? get customerObject => customer is CustomerModel ? customer as CustomerModel : null;
  String get customerId => customer is CustomerModel ? (customer as CustomerModel).id : customer.toString();
}
