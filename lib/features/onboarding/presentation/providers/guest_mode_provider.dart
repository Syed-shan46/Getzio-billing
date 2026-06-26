import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/core/storage/hive_service.dart';
import 'package:getzio_billing/core/router/app_router.dart';

/// Keys for Hive preferences
const String _kHasSeenOnboarding = 'hasSeenOnboarding';

class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final hive = ref.read(hiveServiceProvider);
    return hive.getPreference(_kHasSeenOnboarding, defaultValue: false) as bool;
  }

  Future<void> complete() async {
    final hive = ref.read(hiveServiceProvider);
    await hive.savePreference(_kHasSeenOnboarding, true);
    state = true;
  }
}

/// Whether the user has completed the onboarding flow.
/// Reads from Hive on first access.
final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingNotifier, bool>(
  HasSeenOnboardingNotifier.new,
);

/// Marks onboarding as completed and persists to Hive.
Future<void> completeOnboarding(WidgetRef ref) async {
  await ref.read(hasSeenOnboardingProvider.notifier).complete();
}

/// Whether the current session is a guest (browsing without auth).
/// True when user has seen onboarding but auth status is guest.
final isGuestModeProvider = Provider<bool>((ref) {
  final authStatus = ref.watch(authStateProvider);
  return authStatus == AuthStatus.guest;
});
