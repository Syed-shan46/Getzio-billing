import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/payments/data/models/payment_model.dart';
import 'package:getzio_billing/features/invoices/presentation/providers/invoice_provider.dart';

class PaymentNotifier extends AsyncNotifier<List<PaymentModel>> {
  @override
  FutureOr<List<PaymentModel>> build() async {
    return _fetchPayments();
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

  Future<List<PaymentModel>> _fetchPayments() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/payments');
      if (response.statusCode == 200) {
        final data = response.data['data']['payments'] as List;
        return data.map((p) => PaymentModel.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw _parseError(e);
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPayments());
  }

  Future<void> addPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'invoiceId': invoiceId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'notes': notes,
      };

      final response = await dio.post('/billing/payments', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh payment history
        await refresh();
        // Also refresh invoices to update their outstanding and status values
        await ref.read(invoiceProvider.notifier).refresh();
      } else {
        state = AsyncValue.error('Failed to register payment.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }
}

final paymentProvider = AsyncNotifierProvider<PaymentNotifier, List<PaymentModel>>(PaymentNotifier.new);
