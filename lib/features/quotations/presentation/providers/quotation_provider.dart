import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/quotations/data/models/quotation_model.dart';

class QuotationNotifier extends AsyncNotifier<List<QuotationModel>> {
  @override
  FutureOr<List<QuotationModel>> build() async {
    return _fetchQuotations();
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

  Future<List<QuotationModel>> _fetchQuotations() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/quotations');
      if (response.statusCode == 200) {
        final data = response.data['data']['quotations'] as List;
        return data.map((q) => QuotationModel.fromJson(q as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw _parseError(e);
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchQuotations());
  }

  Future<void> createQuotation({
    required String customerId,
    required String quotationNumber,
    required String status,
    required DateTime issueDate,
    DateTime? expiryDate,
    required List<QuotationItemModel> items,
    required double subtotal,
    required double taxTotal,
    double discount = 0.0,
    required double total,
    String? notes,
    String? terms,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'customerId': customerId,
        'quotationNumber': quotationNumber,
        'status': status,
        'issueDate': issueDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'discount': discount,
        'total': total,
        'notes': notes,
        'terms': terms,
      };

      final response = await dio.post('/billing/quotations', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to create quotation.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> updateQuotation({
    required String id,
    required String customerId,
    required String quotationNumber,
    required String status,
    required DateTime issueDate,
    DateTime? expiryDate,
    required List<QuotationItemModel> items,
    required double subtotal,
    required double taxTotal,
    double discount = 0.0,
    required double total,
    String? notes,
    String? terms,
    String? convertedInvoiceId,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'customerId': customerId,
        'quotationNumber': quotationNumber,
        'status': status,
        'issueDate': issueDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'discount': discount,
        'total': total,
        'notes': notes,
        'terms': terms,
        if (convertedInvoiceId != null) 'convertedInvoiceId': convertedInvoiceId,
      };

      final response = await dio.put('/billing/quotations/$id', data: payload);
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to update quotation.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }
}

final quotationProvider = AsyncNotifierProvider<QuotationNotifier, List<QuotationModel>>(QuotationNotifier.new);
