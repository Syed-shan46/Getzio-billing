import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/invoices/data/models/invoice_model.dart';

class InvoiceNotifier extends AsyncNotifier<List<InvoiceModel>> {
  @override
  FutureOr<List<InvoiceModel>> build() async {
    return _fetchInvoices();
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

  Future<List<InvoiceModel>> _fetchInvoices() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/invoices');
      if (response.statusCode == 200) {
        final data = response.data['data']['invoices'] as List;
        return data.map((i) => InvoiceModel.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw _parseError(e);
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInvoices());
  }

  Future<void> createInvoice({
    required String customerId,
    required String invoiceNumber,
    required String status,
    required DateTime issueDate,
    DateTime? dueDate,
    required List<InvoiceItemModel> items,
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
        'invoiceNumber': invoiceNumber,
        'status': status,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'discount': discount,
        'total': total,
        'notes': notes,
        'terms': terms,
      };

      final response = await dio.post('/billing/invoices', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to create invoice.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> updateInvoice({
    required String id,
    required String customerId,
    required String invoiceNumber,
    required String status,
    required DateTime issueDate,
    DateTime? dueDate,
    required List<InvoiceItemModel> items,
    required double subtotal,
    required double taxTotal,
    double discount = 0.0,
    required double total,
    double amountPaid = 0.0,
    String? notes,
    String? terms,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'customerId': customerId,
        'invoiceNumber': invoiceNumber,
        'status': status,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'discount': discount,
        'total': total,
        'amountPaid': amountPaid,
        'notes': notes,
        'terms': terms,
      };

      final response = await dio.put('/billing/invoices/$id', data: payload);
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to update invoice.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> deleteInvoice(String id) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.delete('/billing/invoices/$id');
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to delete invoice.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }
}

final invoiceProvider = AsyncNotifierProvider<InvoiceNotifier, List<InvoiceModel>>(InvoiceNotifier.new);
