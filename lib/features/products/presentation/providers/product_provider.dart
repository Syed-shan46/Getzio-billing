import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/products/data/models/product_model.dart';

class ProductNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  FutureOr<List<ProductModel>> build() async {
    return _fetchProducts();
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

  Future<List<ProductModel>> _fetchProducts() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/products');
      if (response.statusCode == 200) {
        final data = response.data['data']['products'] as List;
        return data.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw _parseError(e);
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }

  Future<void> createProduct({
    required String name,
    String? description,
    required double sellingPrice,
    double taxRate = 0.0,
    String unit = 'pcs',
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'name': name,
        'description': description,
        'sellingPrice': sellingPrice,
        'taxRate': taxRate,
        'unit': unit,
        'isActive': true,
      };

      final response = await dio.post('/billing/products', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to create product.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    String? description,
    required double sellingPrice,
    double taxRate = 0.0,
    String unit = 'pcs',
    bool isActive = true,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'name': name,
        'description': description,
        'sellingPrice': sellingPrice,
        'taxRate': taxRate,
        'unit': unit,
        'isActive': isActive,
      };

      final response = await dio.put('/billing/products/$id', data: payload);
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to update product.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.delete('/billing/products/$id');
      if (response.statusCode == 200) {
        await refresh();
      } else {
        state = AsyncValue.error('Failed to delete product.', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(_parseError(e), stack);
    }
  }
}

final productProvider = AsyncNotifierProvider<ProductNotifier, List<ProductModel>>(ProductNotifier.new);
