import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/documents/data/models/document_model.dart';

class DocumentNotifier extends AsyncNotifier<List<DocumentModel>> {
  @override
  FutureOr<List<DocumentModel>> build() async {
    return _fetchDocuments();
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final errMsg = responseData['error'] ?? responseData['message'] ?? responseData['msg'];
        if (errMsg != null) {
          return errMsg.toString();
        }
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  Future<List<DocumentModel>> _fetchDocuments() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/documents');
      if (response.statusCode == 200) {
        final data = response.data['data']['documents'] as List;
        return data.map((d) => DocumentModel.fromJson(d as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw _parseError(e);
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDocuments());
  }

  Future<void> createDocument({
    required String documentType,
    String? customerId,
    required String status,
    required DateTime issueDate,
    DateTime? dueDate,
    DateTime? validUntil,
    AddressModel? billingAddress,
    AddressModel? shippingAddress,
    String? paymentTerms,
    List<String>? referenceNumbers,
    String? purchaseOrderReference,
    ShipmentDetailsModel? shipmentDetails,
    required List<DocumentItemModel> items,
    required double subtotal,
    required double taxTotal,
    double discount = 0.0,
    double shippingCharges = 0.0,
    double roundOff = 0.0,
    required double total,
    String? notes,
    String? internalNotes,
    String? terms,
    String? templateId,
    Map<String, String>? metadata,
    String? documentNumber,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'documentType': documentType,
        if (customerId != null) 'customerId': customerId,
        'status': status,
        'issueDate': issueDate.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (validUntil != null) 'validUntil': validUntil.toIso8601String(),
        if (billingAddress != null) 'billingAddress': billingAddress.toJson(),
        if (shippingAddress != null) 'shippingAddress': shippingAddress.toJson(),
        if (paymentTerms != null) 'paymentTerms': paymentTerms,
        if (referenceNumbers != null) 'referenceNumbers': referenceNumbers,
        if (purchaseOrderReference != null) 'purchaseOrderReference': purchaseOrderReference,
        if (shipmentDetails != null) 'shipmentDetails': shipmentDetails.toJson(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'discount': discount,
        'shippingCharges': shippingCharges,
        'roundOff': roundOff,
        'total': total,
        if (notes != null) 'notes': notes,
        if (internalNotes != null) 'internalNotes': internalNotes,
        if (terms != null) 'terms': terms,
        if (templateId != null) 'templateId': templateId,
        if (metadata != null) 'metadata': metadata,
        if (documentNumber != null && documentNumber.trim().isNotEmpty) 'documentNumber': documentNumber.trim(),
      };

      final response = await dio.post('/billing/documents', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to create document.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
      rethrow;
    }
  }

  Future<void> updateDocument({
    required String id,
    required String documentType,
    String? customerId,
    required String status,
    required DateTime issueDate,
    DateTime? dueDate,
    DateTime? validUntil,
    AddressModel? billingAddress,
    AddressModel? shippingAddress,
    String? paymentTerms,
    List<String>? referenceNumbers,
    String? purchaseOrderReference,
    ShipmentDetailsModel? shipmentDetails,
    required List<DocumentItemModel> items,
    required double subtotal,
    required double taxTotal,
    double discount = 0.0,
    double shippingCharges = 0.0,
    double roundOff = 0.0,
    required double total,
    double amountPaid = 0.0,
    String? notes,
    String? internalNotes,
    String? terms,
    String? templateId,
    Map<String, String>? metadata,
    required String documentNumber,
    int version = 1,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'documentType': documentType,
        if (customerId != null) 'customerId': customerId,
        'status': status,
        'issueDate': issueDate.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (validUntil != null) 'validUntil': validUntil.toIso8601String(),
        if (billingAddress != null) 'billingAddress': billingAddress.toJson(),
        if (shippingAddress != null) 'shippingAddress': shippingAddress.toJson(),
        if (paymentTerms != null) 'paymentTerms': paymentTerms,
        if (referenceNumbers != null) 'referenceNumbers': referenceNumbers,
        if (purchaseOrderReference != null) 'purchaseOrderReference': purchaseOrderReference,
        if (shipmentDetails != null) 'shipmentDetails': shipmentDetails.toJson(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'discount': discount,
        'shippingCharges': shippingCharges,
        'roundOff': roundOff,
        'total': total,
        'amountPaid': amountPaid,
        if (notes != null) 'notes': notes,
        if (internalNotes != null) 'internalNotes': internalNotes,
        if (terms != null) 'terms': terms,
        if (templateId != null) 'templateId': templateId,
        if (metadata != null) 'metadata': metadata,
        'documentNumber': documentNumber,
        'version': version,
      };

      final response = await dio.put('/billing/documents/$id', data: payload);
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to update document.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.delete('/billing/documents/$id');
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to delete document.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
      rethrow;
    }
  }

  Future<void> convertDocument(String id, {String targetType = 'invoice'}) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.post('/billing/documents/$id/convert', data: {'targetType': targetType});
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to convert document.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
      rethrow;
    }
  }

  Future<void> duplicateDocument(String id) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.post('/billing/documents/$id/duplicate');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to duplicate document.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
      rethrow;
    }
  }

  Future<void> requestApproval(String id) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/billing/documents/$id/approval');
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveDocument(String id, String comments) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/billing/documents/$id/approve', data: {'comments': comments});
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectDocument(String id, String comments) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/billing/documents/$id/reject', data: {'comments': comments});
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

final documentProvider = AsyncNotifierProvider<DocumentNotifier, List<DocumentModel>>(DocumentNotifier.new);
