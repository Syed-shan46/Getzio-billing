import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:getzio_billing/core/network/dio_client.dart';
import 'package:getzio_billing/core/storage/secure_storage_service.dart';
import 'package:getzio_billing/core/router/app_router.dart';
import 'package:getzio_billing/core/services/firebase_service.dart';
import 'package:getzio_billing/features/company/presentation/providers/company_provider.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;

  AuthState({
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.phoneNumber,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? verificationId,
    String? phoneNumber,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Dio get _dio => ref.read(dioProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);
  AuthStatusNotifier get _routerAuthNotifier => ref.read(authStateProvider.notifier);

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    final cleanPhone = phoneNumber.replaceFirst('+91', '').trim();
    if (cleanPhone == '8888888888' || cleanPhone == '9999999999') {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isLoading: false,
        verificationId: 'dummy_verification_id_test',
        phoneNumber: phoneNumber,
      );
      print('[TEST BYPASS] OTP code "123456" simulated for phone: $phoneNumber');
      return;
    }

    try {
      final verificationId = await FirebaseService.sendOTP(phoneNumber: phoneNumber);
      state = state.copyWith(
        isLoading: false,
        verificationId: verificationId,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    if (state.verificationId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (state.verificationId == 'dummy_verification_id_test') {
      await Future.delayed(const Duration(seconds: 1));
      if (smsCode == '123456') {
        await _signInWithCredential(
          uid: 'dummy_uid_test',
          idToken: 'dummy_id_token',
          phoneNumber: state.phoneNumber!,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid code. Use 123456 for testing.');
      }
      return;
    }

    try {
      final result = await FirebaseService.verifyOTP(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      if (result == null) {
        throw Exception("Verification failed. Please try again.");
      }

      final uid = result['uid']!;
      final idToken = result['idToken']!;

      await _signInWithCredential(
        uid: uid,
        idToken: idToken,
        phoneNumber: state.phoneNumber!,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _signInWithCredential({
    required String uid,
    required String idToken,
    required String phoneNumber,
  }) async {
    try {
      // Authenticate with Getzio Backend
      final response = await _dio.post('/user/auth/firebase', data: {
        'phoneNumber': phoneNumber,
        'firebaseUid': uid,
        'idToken': idToken,
      });

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        await _storage.saveToken(token);
        
        state = state.copyWith(isLoading: false);
        ref.invalidate(companyProvider);
        _routerAuthNotifier.setAuthenticated(true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Backend authentication failed.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseService.signOut();
    } catch (_) {}
    await _storage.deleteToken();
    ref.invalidate(companyProvider);
    _routerAuthNotifier.setAuthenticated(false);
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Call backend to delete profile
      await _dio.delete('/user/profile');

      // 2. Call Firebase to delete user profile
      try {
        await FirebaseService.deleteAccount();
      } catch (_) {}

      // 3. Clear storage, invalidate providers and redirect
      await _storage.deleteToken();
      ref.invalidate(companyProvider);
      state = state.copyWith(isLoading: false);
      _routerAuthNotifier.setAuthenticated(false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

