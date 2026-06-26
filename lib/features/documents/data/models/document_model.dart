import 'package:getzio_billing/features/customers/data/models/customer_model.dart';

class DocumentItemModel {
  final String? productId;
  final String name;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double total;

  DocumentItemModel({
    this.productId,
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    required this.total,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      productId: json['productId'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
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
      'discount': discount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
    };
  }
}

class AddressModel {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  AddressModel({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AddressModel();
    return AddressModel(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}

class ShipmentDetailsModel {
  final String? carrier;
  final String? trackingNumber;
  final String? portOfLoading;
  final String? portOfDischarge;
  final String? vesselName;

  ShipmentDetailsModel({
    this.carrier,
    this.trackingNumber,
    this.portOfLoading,
    this.portOfDischarge,
    this.vesselName,
  });

  factory ShipmentDetailsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ShipmentDetailsModel();
    return ShipmentDetailsModel(
      carrier: json['carrier'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      portOfLoading: json['portOfLoading'] as String?,
      portOfDischarge: json['portOfDischarge'] as String?,
      vesselName: json['vesselName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carrier': carrier,
      'trackingNumber': trackingNumber,
      'portOfLoading': portOfLoading,
      'portOfDischarge': portOfDischarge,
      'vesselName': vesselName,
    };
  }
}

class DocumentModel {
  final String id;
  final dynamic customer;
  final String documentType;
  final String documentNumber;
  final String status;
  final String financialYear;
  final String currency;
  final String language;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? validUntil;
  final AddressModel billingAddress;
  final AddressModel shippingAddress;
  final String? paymentTerms;
  final List<String> referenceNumbers;
  final String? purchaseOrderReference;
  final ShipmentDetailsModel shipmentDetails;
  final List<DocumentItemModel> items;
  final double subtotal;
  final double taxTotal;
  final double discount;
  final double shippingCharges;
  final double roundOff;
  final double total;
  final double amountPaid;
  final String? notes;
  final String? internalNotes;
  final String? terms;

  // Conversion tracking
  final String? convertedFromType;
  final String? convertedFromId;
  final String? convertedToId;

  // Customization
  final String templateId;
  final Map<String, String> metadata;

  // Audit and Version Control
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvalTime;
  final String? pdfUrl;
  final int version;

  DocumentModel({
    required this.id,
    this.customer,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.financialYear,
    required this.currency,
    required this.language,
    required this.issueDate,
    this.dueDate,
    this.validUntil,
    required this.billingAddress,
    required this.shippingAddress,
    this.paymentTerms,
    this.referenceNumbers = const [],
    this.purchaseOrderReference,
    required this.shipmentDetails,
    required this.items,
    this.subtotal = 0.0,
    this.taxTotal = 0.0,
    this.discount = 0.0,
    this.shippingCharges = 0.0,
    this.roundOff = 0.0,
    required this.total,
    this.amountPaid = 0.0,
    this.notes,
    this.internalNotes,
    this.terms,
    this.convertedFromType,
    this.convertedFromId,
    this.convertedToId,
    this.templateId = 'modern',
    this.metadata = const {},
    this.createdBy,
    this.approvedBy,
    this.approvalTime,
    this.pdfUrl,
    this.version = 1,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    dynamic customerData = json['customerId'];
    if (customerData is Map<String, dynamic>) {
      customerData = CustomerModel.fromJson(customerData);
    }

    Map<String, String> meta = {};
    if (json['metadata'] != null && json['metadata'] is Map) {
      (json['metadata'] as Map).forEach((key, value) {
        meta[key.toString()] = value.toString();
      });
    }

    List<String> refs = [];
    if (json['referenceNumbers'] != null && json['referenceNumbers'] is List) {
      refs = (json['referenceNumbers'] as List).map((r) => r.toString()).toList();
    }

    return DocumentModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      customer: customerData,
      documentType: json['documentType'] as String? ?? 'invoice',
      documentNumber: json['documentNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      financialYear: json['financialYear'] as String? ?? '',
      currency: json['currency'] as String? ?? 'INR',
      language: json['language'] as String? ?? 'en',
      issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate']) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil']) : null,
      billingAddress: AddressModel.fromJson(json['billingAddress'] as Map<String, dynamic>?),
      shippingAddress: AddressModel.fromJson(json['shippingAddress'] as Map<String, dynamic>?),
      paymentTerms: json['paymentTerms'] as String?,
      referenceNumbers: refs,
      purchaseOrderReference: json['purchaseOrderReference'] as String?,
      shipmentDetails: ShipmentDetailsModel.fromJson(json['shipmentDetails'] as Map<String, dynamic>?),
      items: json['items'] != null
          ? (json['items'] as List).map((i) => DocumentItemModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shippingCharges: (json['shippingCharges'] as num?)?.toDouble() ?? 0.0,
      roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      internalNotes: json['internalNotes'] as String?,
      terms: json['terms'] as String?,
      convertedFromType: json['convertedFromType'] as String?,
      convertedFromId: json['convertedFromId'] as String?,
      convertedToId: json['convertedToId'] as String?,
      templateId: json['templateId'] as String? ?? 'modern',
      metadata: meta,
      createdBy: json['createdBy'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvalTime: json['approvalTime'] != null ? DateTime.parse(json['approvalTime']) : null,
      pdfUrl: json['pdfUrl'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customer is CustomerModel ? (customer as CustomerModel).id : customer,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'status': status,
      'financialYear': financialYear,
      'currency': currency,
      'language': language,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'billingAddress': billingAddress.toJson(),
      'shippingAddress': shippingAddress.toJson(),
      'paymentTerms': paymentTerms,
      'referenceNumbers': referenceNumbers,
      'purchaseOrderReference': purchaseOrderReference,
      'shipmentDetails': shipmentDetails.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'taxTotal': taxTotal,
      'discount': discount,
      'shippingCharges': shippingCharges,
      'roundOff': roundOff,
      'total': total,
      'amountPaid': amountPaid,
      'notes': notes,
      'internalNotes': internalNotes,
      'terms': terms,
      'convertedFromType': convertedFromType,
      'convertedFromId': convertedFromId,
      'convertedToId': convertedToId,
      'templateId': templateId,
      'metadata': metadata,
      'version': version,
    };
  }

  CustomerModel? get customerObject => customer is CustomerModel ? customer as CustomerModel : null;
  String? get customerId => customer != null ? (customer is CustomerModel ? (customer as CustomerModel).id : customer.toString()) : null;

  String get documentTypeLabel {
    return documentType.split('_').map((word) {
      if (word.isEmpty) return '';
      if (word.toLowerCase() == 'gst') return 'GST';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String get documentTypePrefix {
    switch (documentType) {
      case 'invoice':
      case 'gst_invoice':
      case 'tax_invoice':
      case 'retail_invoice':
        return 'INV';
      case 'proforma_invoice':
        return 'PRO';
      case 'quotation':
        return 'QT';
      case 'estimate':
        return 'EST';
      case 'purchase_order':
        return 'PO';
      case 'delivery_challan':
        return 'DC';
      case 'receipt':
        return 'REC';
      case 'credit_note':
        return 'CR';
      case 'debit_note':
        return 'DR';
      case 'stock_transfer':
        return 'ST';
      case 'stock_adjustment':
        return 'SA';
      case 'work_order':
        return 'WO';
      case 'job_card':
        return 'JC';
      case 'offer_letter':
        return 'OL';
      case 'appointment_letter':
        return 'AL';
      default:
        return 'DOC';
    }
  }
}
