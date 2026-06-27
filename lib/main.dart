import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/core/theme/app_theme.dart';
import 'package:getzio_billing/core/router/app_router.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:getzio_billing/core/storage/hive_service.dart';

import 'package:getzio_billing/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  try {
    await hiveService.init();
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [hiveServiceProvider.overrideWithValue(hiveService)],
      child: const GetzioBillingApp(),
    ),
  );
}

class GetzioBillingApp extends ConsumerWidget {
  const GetzioBillingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Getzio Desk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
