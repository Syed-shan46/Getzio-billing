import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';
import 'package:getzio_billing/core/router/app_router.dart';
import 'package:getzio_billing/features/onboarding/presentation/providers/guest_mode_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const _pages = [
    _OnboardingPageData(
      emoji: '📄',
      accentColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFF818CF8),
      title: 'Create Professional\nDocuments',
      subtitle:
          'Generate beautiful invoices, quotations, and purchase orders in seconds with customizable templates.',
      features: ['Invoices & Quotations', 'Purchase Orders', 'Credit Notes'],
    ),
    _OnboardingPageData(
      emoji: '📊',
      accentColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF34D399),
      title: 'Track Your\nBusiness',
      subtitle:
          'Keep a complete record of customers, products, and payments. Your entire ledger in one place.',
      features: ['Customer Directory', 'Product Catalog', 'Payment Ledger'],
    ),
    _OnboardingPageData(
      emoji: '🎨',
      accentColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFFBBF24),
      title: 'Beautiful\nTemplates',
      subtitle:
          'Choose from multiple professionally designed PDF templates. Customize colors, logos, and layouts.',
      features: ['Multiple Designs', 'Custom Branding', 'PDF Export'],
    ),
    _OnboardingPageData(
      emoji: '☁️',
      accentColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFFA78BFA),
      title: 'Sync\nEverywhere',
      subtitle:
          'Your data is securely backed up to the cloud. Access your business from any device, anytime.',
      features: ['Cloud Backup', 'Multi-Device', 'Secure & Encrypted'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await completeOnboarding(ref);
    if (!mounted) return;
    context.go('/create-workspace');
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = _pages[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFAFAFA),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Top bar: Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page counter
                      Text(
                        '${_currentPage + 1}/${_pages.length}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      // Skip button
                      if (_currentPage < _pages.length - 1)
                        GestureDetector(
                          onTap: _completeOnboarding,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 60),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(data: _pages[index], isDark: isDark);
                    },
                  ),
                ),

                // Bottom: indicator + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      // Expanding dot indicator
                      _ExpandingDotIndicator(
                        count: _pages.length,
                        current: _currentPage,
                        activeColor: page.accentColor,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Continue / Get Started button
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: 56,
                          decoration: BoxDecoration(
                            color: page.accentColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: page.accentColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Continue',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Page Data Model ──────────────────────────────────────────────────────────

class _OnboardingPageData {
  final String emoji;
  final Color accentColor;
  final Color secondaryColor;
  final String title;
  final String subtitle;
  final List<String> features;

  const _OnboardingPageData({
    required this.emoji,
    required this.accentColor,
    required this.secondaryColor,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}

// ─── Single Onboarding Page ───────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isDark;

  const _OnboardingPage({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Illustration area: large emoji with glow ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  data.accentColor.withOpacity(0.12),
                  data.accentColor.withOpacity(0.03),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? data.accentColor.withOpacity(0.08)
                      : data.accentColor.withOpacity(0.06),
                  border: Border.all(
                    color: data.accentColor.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    data.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 44),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.8,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.55,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: 28),

          // Feature chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data.features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? data.accentColor.withOpacity(0.08)
                      : data.accentColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: data.accentColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  feature,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: data.accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─── Expanding Dot Indicator ──────────────────────────────────────────────────

class _ExpandingDotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;
  final bool isDark;

  const _ExpandingDotIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? activeColor
                : (isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08)),
          ),
        );
      }),
    );
  }
}
