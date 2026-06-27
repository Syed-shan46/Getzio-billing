import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/features/company/data/models/company_model.dart';
import 'package:getzio_billing/core/storage/secure_storage_service.dart';

class CompanyNotifier extends AsyncNotifier<CompanyModel?> {
  @override
  FutureOr<CompanyModel?> build() async {
    return _fetchCompany();
  }

  Future<CompanyModel?> _fetchCompany() async {
    final token = await ref.read(secureStorageProvider).getToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/company');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null || data['company'] == null) {
          return null;
        }
        return CompanyModel.fromJson(data['company'] as Map<String, dynamic>);
      }
    } catch (e) {
      // Return null or rethrow based on preference. Let's return null to signify setup needed.
      return null;
    }
    return null;
  }

  Future<void> saveCompany({
    required String companyName,
    String? gstNumber,
    String? phone,
    String? email,
    String? website,
    required CompanyAddress address,
    required BankDetails bankDetails,
    String? logoBase64,
    String? signatureBase64,
    String? stampBase64,
    String? defaultTemplate,
  }) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      final payload = {
        'companyName': companyName,
        'gstNumber': gstNumber,
        'phone': phone,
        'email': email,
        'website': website,
        'address': address.toJson(),
        'bankDetails': bankDetails.toJson(),
        if (logoBase64 != null) 'logo': logoBase64,
        if (signatureBase64 != null) 'signature': signatureBase64,
        if (stampBase64 != null) 'stamp': stampBase64,
        if (defaultTemplate != null) 'defaultTemplate': defaultTemplate,
      };
      
      final response = await dio.post('/billing/company', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data']['company'];
        final updated = CompanyModel.fromJson(data as Map<String, dynamic>);
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.error('Failed to save company details.', StackTrace.current);
      }
    } catch (e, stack) {
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          state = AsyncValue.error(responseData['message'].toString(), stack);
          return;
        }
      }
      state = AsyncValue.error(e, stack);
    }
  }
}

final companyProvider = AsyncNotifierProvider<CompanyNotifier, CompanyModel?>(CompanyNotifier.new);
