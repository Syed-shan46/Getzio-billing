import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/customers/data/models/customer_model.dart';

class CustomerNotifier extends AsyncNotifier<List<CustomerModel>> {
  @override
  FutureOr<List<CustomerModel>> build() async {
    return _fetchCustomers();
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

  Future<List<CustomerModel>> _fetchCustomers() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/customers');
      if (response.statusCode == 200) {
        final data = response.data['data']['customers'] as List;
        return data.map((c) => CustomerModel.fromJson(c as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw _parseError(e);
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<void> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? gstNumber,
    required CustomerAddress address,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'gstNumber': gstNumber,
        'address': address.toJson(),
        'notes': notes,
      };

      final response = await dio.post('/billing/customers', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to create customer.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? gstNumber,
    required CustomerAddress address,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'gstNumber': gstNumber,
        'address': address.toJson(),
        'notes': notes,
      };

      final response = await dio.put('/billing/customers/$id', data: payload);
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to update customer.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.delete('/billing/customers/$id');
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to delete customer.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }
}

final customerProvider = AsyncNotifierProvider<CustomerNotifier, List<CustomerModel>>(CustomerNotifier.new);
