import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';
import 'package:getzio_billing/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:getzio_billing/features/auth/presentation/screens/otp_screen.dart';
import 'package:getzio_billing/features/auth/presentation/screens/splash_screen.dart';
import 'package:getzio_billing/features/company/presentation/providers/company_provider.dart';
import 'package:getzio_billing/features/company/data/models/company_model.dart';
import 'package:getzio_billing/features/company/presentation/screens/company_setup_screen.dart';
import 'package:getzio_billing/features/company/presentation/screens/success_screen.dart';
import 'package:getzio_billing/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:getzio_billing/features/customers/presentation/screens/customers_screen.dart';
import 'package:getzio_billing/features/products/presentation/screens/products_screen.dart';
import 'package:getzio_billing/features/documents/presentation/screens/documents_screen.dart';
import 'package:getzio_billing/features/more/presentation/screens/more_screen.dart';
import 'package:getzio_billing/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:getzio_billing/features/invoices/presentation/screens/create_invoice_screen.dart';
import 'package:getzio_billing/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:getzio_billing/features/onboarding/presentation/screens/create_workspace_screen.dart';
import 'package:getzio_billing/features/onboarding/presentation/providers/guest_mode_provider.dart';
import 'package:getzio_billing/features/reports/presentation/screens/reports_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

enum AuthStatus { checking, authenticated, unauthenticated, guest }

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.checking;

  void setAuthenticated(bool value) {
    state = value ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  void setGuest() {
    state = AuthStatus.guest;
  }
}

final authStateProvider = NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    ref.listen<AuthStatus>(authStateProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<CompanyModel?>>(companyProvider, (_, __) => notifyListeners());
    ref.listen<bool>(hasSeenOnboardingProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = RouterRefreshListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authStatus = ref.read(authStateProvider);
      final companyState = ref.read(companyProvider);
      final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);

      debugPrint('[GoRouter Redirect] Path: ${state.matchedLocation}, authStatus: $authStatus, hasSeenOnboarding: $hasSeenOnboarding');

      if (authStatus == AuthStatus.checking) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      // 1. Onboarding Gate
      if (!hasSeenOnboarding) {
        return state.matchedLocation == '/onboarding' ? null : '/onboarding';
      }

      // 2. Authentication Gate
      final isAuthenticated = authStatus == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/create-workspace';

      if (!isAuthenticated) {
        return isAuthRoute ? null : '/create-workspace';
      }

      // 3. Business Profile / Company Gate
      final companyValue = companyState.value;
      final hasCompany = companyValue != null;
      final isSetupRoute = state.matchedLocation == '/company-setup' || state.matchedLocation == '/success';

      if (companyState.isLoading) {
        return null; // Stay put while loading company status
      }

      if (!hasCompany) {
        return isSetupRoute ? null : '/company-setup';
      }

      if (isAuthRoute ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/company-setup' ||
          state.matchedLocation == '/onboarding') {
        return '/';
      }

      return null;
    },
    routes: [
      // ─── Splash Route ──
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ─── Onboarding Route ──
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ─── Create Workspace Route ──
      GoRoute(
        path: '/create-workspace',
        builder: (_, __) => const CreateWorkspaceScreen(),
      ),

      // ─── Auth Routes ──
      GoRoute(
        path: '/login',
        builder: (_, __) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, __) => const OtpScreen(),
      ),

      // ─── Company Setup Route ──
      GoRoute(
        path: '/company-setup',
        builder: (_, __) => const CompanySetupScreen(),
      ),

      // ─── Success Route ──
      GoRoute(
        path: '/success',
        builder: (_, __) => const SuccessScreen(),
      ),

      // ─── Invoices Route ──
      GoRoute(
        path: '/invoices',
        builder: (context, state) {
          final action = state.uri.queryParameters['action'];
          if (action == 'create') {
            return const CreateInvoiceScreen();
          }
          return const InvoicesScreen();
        },
      ),

      // ─── Main Shell ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/documents',
            builder: (_, __) => const DocumentsScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) {
              final action = state.uri.queryParameters['action'];
              return CustomersScreen(showCreateForm: action == 'create');
            },
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              final action = state.uri.queryParameters['action'];
              return ProductsScreen(showCreateForm: action == 'create');
            },
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const MoreScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Main shell with bottom navigation bar for iOS feel.
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  static final _tabs = [
    const _TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/'),
    const _TabItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Documents', path: '/documents'),
    const _TabItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers', path: '/customers'),
    const _TabItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Products', path: '/products'),
    const _TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports', path: '/reports'),
    const _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      extendBody: true, // Enable to make margins and glass background transparent to pages
      body: child,
      bottomNavigationBar: CustomFloatingNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabs[index].path),
        items: _tabs,
      ),
    );
  }
}

class CustomFloatingNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> items;

  const CustomFloatingNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      bottom: true, // Automatically respect bottom safe areas natively
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceDark : Colors.white).withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Navigation Items
                  Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isActive = index == currentIndex;
                      return Expanded(
                        child: _NavBarItem(
                          item: item,
                          isActive: isActive,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onTap(index);
                          },
                          activeColor: activeColor,
                          isDark: isDark,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _TabItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isDark;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final themeTextSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scale and color for the icon
          AnimatedScale(
            scale: isActive ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? activeColor : themeTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 3),
          // Animated text style and color
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : themeTextSecondary,
              fontFamily: 'Plus Jakarta Sans',
              letterSpacing: -0.1,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
