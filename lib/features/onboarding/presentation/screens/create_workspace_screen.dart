import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';

class CreateWorkspaceScreen extends StatelessWidget {
  const CreateWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            left: size.width * 0.1,
            child: Container(
              width: size.width * 0.8,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(isDark ? 0.15 : 0.06),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Body
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Hero Floating Illustration
                  const _FloatingHeroSection(),

                  const SizedBox(height: 36),

                  // Headline & Subtitle
                  Text(
                    'Create Your Business Workspace',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Everything your business needs in one secure workspace. Create professional documents, manage customers, organize products, and grow with powerful insights.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Benefits Grid
                  Text(
                    'WORKSPACE CAPABILITIES',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.blueAccent : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _BenefitsSection(),

                  const SizedBox(height: 48),

                  // Document Mock Previews
                  Text(
                    'PROFESSIONAL TEMPLATES',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.blueAccent : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _DocumentMockPreviews(),

                  const SizedBox(height: 48),

                  // Trust/Security Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your data is securely stored and synced across all your devices.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Primary CTA
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Create My Workspace',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary CTA
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showLearnMoreModal(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Learn More',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLearnMoreModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'About Getzio Desk',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const SizedBox(height: 8),
                    _buildLearnItem(
                      icon: Icons.auto_awesome_outlined,
                      title: 'All-in-One Professional Workspace',
                      description: 'Create and dispatch GST invoices, professional quotations, purchase orders, credit notes, and delivery slips seamlessly.',
                    ),
                    const SizedBox(height: 16),
                    _buildLearnItem(
                      icon: Icons.cloud_done_outlined,
                      title: 'Instant Sync & Multi-Device Support',
                      description: 'Real-time database sync lets you run your business concurrently across mobile, tablet, and desktop versions.',
                    ),
                    const SizedBox(height: 16),
                    _buildLearnItem(
                      icon: Icons.shield_outlined,
                      title: 'Enterprise-Grade Security',
                      description: 'Your financial logs, client directories, and catalog information are end-to-end encrypted and safely hosted on secure servers.',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLearnItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloatingHeroSection extends StatefulWidget {
  const _FloatingHeroSection();

  @override
  State<_FloatingHeroSection> createState() => _FloatingHeroSectionState();
}

class _FloatingHeroSectionState extends State<_FloatingHeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final dy = _animController.value * 12.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Central Workspace Glowing Cube
              Transform.translate(
                offset: Offset(0, dy * -0.5),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.24),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🏢',
                      style: TextStyle(fontSize: 44),
                    ),
                  ),
                ),
              ),

              // Floating Item 1: Invoice (Top Left)
              _buildFloatingItem(
                emoji: '📄',
                offset: Offset(-80, -60 + dy),
                label: 'Invoice',
              ),
              // Floating Item 2: Quotation (Top Right)
              _buildFloatingItem(
                emoji: '💬',
                offset: Offset(80, -50 - dy),
                label: 'Quote',
              ),
              // Floating Item 3: Purchase Order (Bottom Left)
              _buildFloatingItem(
                emoji: '🛒',
                offset: Offset(-90, 40 - dy),
                label: 'Order',
              ),
              // Floating Item 4: Delivery Note (Bottom Right)
              _buildFloatingItem(
                emoji: '🚚',
                offset: Offset(90, 50 + dy),
                label: 'Delivery',
              ),
              // Floating Item 5: Customer Card (Far Left)
              _buildFloatingItem(
                emoji: '👥',
                offset: Offset(-120, -10 + dy * 0.5),
                label: 'Client',
              ),
              // Floating Item 6: Product Box (Far Right)
              _buildFloatingItem(
                emoji: '📦',
                offset: Offset(120, -10 - dy * 0.5),
                label: 'Product',
              ),
              // Floating Item 7: Analytics Chart (Top Center)
              _buildFloatingItem(
                emoji: '📊',
                offset: Offset(0, -90 + dy * 0.7),
                label: 'Insights',
              ),
              // Floating Item 8: Cloud Sync (Bottom Center Left)
              _buildFloatingItem(
                emoji: '☁️',
                offset: Offset(-40, 85 - dy * 0.8),
                label: 'Sync',
              ),
              // Floating Item 9: Security Shield (Bottom Center Right)
              _buildFloatingItem(
                emoji: '🛡️',
                offset: Offset(40, 85 + dy * 0.8),
                label: 'Secure',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingItem({
    required String emoji,
    required Offset offset,
    required String label,
  }) {
    return Transform.translate(
      offset: offset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  static const _benefits = [
    {'title': '42 Professional Documents', 'desc': 'Invoices, receipts, delivery slips, purchase orders & more.'},
    {'title': 'GST Invoices & Quotations', 'desc': 'Beautiful, tax-compliant layouts with direct PDF exports.'},
    {'title': 'Customer & Product Hub', 'desc': 'Quick directory lookups, inventories, and pricing lists.'},
    {'title': 'Business Analytics & Reports', 'desc': 'Track outstanding dues, sales progress, and revenue data.'},
    {'title': 'Secure Cloud Syncing', 'desc': 'No manual backup needed. Everything is safe and cloud-synced.'},
    {'title': 'Approval Workflows', 'desc': 'Request manager signatures or approvals before dispatching files.'},
    {'title': 'Audit Logs & Histories', 'desc': 'Trace document edits, client activities, and version trails.'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _benefits.length,
      itemBuilder: (context, index) {
        final b = _benefits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.blue,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['title']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b['desc']!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentMockPreviews extends StatelessWidget {
  const _DocumentMockPreviews();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Mock Invoice
          _buildMockDocCard(
            title: 'TAX INVOICE',
            number: '#INV-2026-0042',
            client: 'Stripe Payments Ltd.',
            amount: '₹42,500.00',
            badge: 'PAID',
            badgeColor: const Color(0xFF10B981),
            cardBg: cardBg,
            borderCol: borderCol,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          // Mock Quotation
          _buildMockDocCard(
            title: 'BUSINESS QUOTE',
            number: '#QT-2026-0089',
            client: 'Linear Design Studio',
            amount: '₹1,20,000.00',
            badge: 'SENT',
            badgeColor: Colors.blue,
            cardBg: cardBg,
            borderCol: borderCol,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          // Mock PO
          _buildMockDocCard(
            title: 'PURCHASE ORDER',
            number: '#PO-2026-0150',
            client: 'Framer Hosting Corp.',
            amount: '₹84,300.00',
            badge: 'APPROVED',
            badgeColor: Colors.purple,
            cardBg: cardBg,
            borderCol: borderCol,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          // Mock Delivery
          _buildMockDocCard(
            title: 'DELIVERY CHALLAN',
            number: '#DC-2026-0033',
            client: 'Acme Logistics Inc.',
            amount: '12 Box (Weight: 45Kg)',
            badge: 'DELIVERED',
            badgeColor: Colors.teal,
            cardBg: cardBg,
            borderCol: borderCol,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMockDocCard({
    required String title,
    required String number,
    required String client,
    required String amount,
    required String badge,
    required Color badgeColor,
    required Color cardBg,
    required Color borderCol,
    required bool isDark,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            client,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Value',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
