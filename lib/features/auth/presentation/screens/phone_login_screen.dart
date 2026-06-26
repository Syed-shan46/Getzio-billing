import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  String? _validationError;

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (ref.read(authProvider).isLoading) return;
    
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() {
        _validationError = 'Please enter a valid 10-digit mobile number';
      });
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _validationError = null;
    });
    HapticFeedback.mediumImpact();

    final formattedPhone = '+91$phone';
    ref.read(authProvider.notifier).sendOtp(formattedPhone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next.verificationId != null && (previous?.verificationId != next.verificationId)) {
        context.push('/otp');
      }
    });

    final displayError = _validationError ?? authState.error;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // Background Slate Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF020617), // Slate 950
                ],
              ),
            ),
          ),

          // Top Accent Glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Accent Glow
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.1),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Logo Container (same style as SplashScreen)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, err, stack) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.receipt_long, size: 50, color: AppColors.primary),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Titles
                    Text(
                      'Getzio Desk',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Professional Invoicing & Ledger',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Glassmorphic Input Card
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ENTER MOBILE NUMBER',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Input Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: displayError != null
                                    ? AppColors.error.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.08),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '+91',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    focusNode: _focusNode,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    cursorColor: AppColors.primary,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      hintText: '00000 00000',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.25),
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      counterText: '',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onSubmitted: (_) => _sendOtp(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (displayError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              displayError,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Custom Continue Button
                          GestureDetector(
                            onTap: authState.isLoading ? null : _sendOtp,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Get Verification Code',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Disclaimer
                          Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.4),
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'By continuing, you agree to our '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _showPolicySheet(
                                          'Terms of Service',
                                          [
                                            _buildParagraph(context, 'By downloading, installing, or utilizing the Getzio Desk mobile application, you agree to comply with and be bound by the following Terms of Service. Please inspect these terms carefully before starting.'),
                                            _buildSectionHeader(context, '1. Scope of Agreement'),
                                            _buildParagraph(context, 'Getzio Desk offers local and cloud-synced invoice management, ledger tracking, and business document formatting (PDF generation). These services are provided "as-is" and "as available".'),
                                            _buildSectionHeader(context, '2. Account & Security'),
                                            _buildParagraph(context, 'Accessing the app requires valid mobile verification (OTP). You are solely responsible for maintaining the privacy of your mobile number and credentials, and for all business invoices, ledgers, and catalog records entered under your authenticated session.'),
                                            _buildSectionHeader(context, '3. Proper Usage Regulations'),
                                            _buildParagraph(context, 'You agree to employ Getzio Desk exclusively for legitimate, legal business transactions. You must not use our software to construct fraudulent documents, bypass tax requirements, transmit malicious codes, or disrupt cloud routing networks.'),
                                            _buildSectionHeader(context, '4. Tax and Legal Responsibilities'),
                                            _buildParagraph(context, 'Getzio Desk supplies generic invoice design sheets, automated GST computations, and tax templates. However, the calculation accuracy and compliance of tax fields remain your sole legal duty. We are not responsible for audits, incorrect tax rates, or regulatory filing penalties.'),
                                            _buildSectionHeader(context, '5. Limitation of Liability'),
                                            _buildParagraph(context, 'Under no circumstances shall Getzio Desk, its developers, or its cloud hosts be liable for direct, incidental, or consequential business damages (including loss of profits, records deletion, database issues, or device crashes) resulting from the use or inability to use this software.'),
                                            _buildSectionHeader(context, '6. Modification of Terms'),
                                            _buildParagraph(context, 'We reserve the right to modify these terms from time to time. Your continued use of the application following updates constitutes your binding agreement to the revised Terms of Service.'),
                                          ],
                                        );
                                      },
                                  ),
                                  const TextSpan(text: ' & '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _showPolicySheet(
                                          'Privacy Policy',
                                          [
                                            _buildParagraph(context, 'Welcome to Getzio Desk. We value your privacy and are committed to protecting your personal and business data. This Privacy Policy details how we collect, use, and safeguard your information when you use our mobile application and related services.'),
                                            _buildSectionHeader(context, '1. Information We Collect'),
                                            _buildBulletPoint(context, 'Personal Identification Details: Mobile phone numbers (used for OTP authentication) and optional contact email addresses.'),
                                            _buildBulletPoint(context, 'Business Profile details: Business name, logo, physical address, GSTIN/Tax identification numbers, and optionally bank coordinates (bank name, account number, IFSC code) to display on your generated invoices.'),
                                            _buildBulletPoint(context, 'Transaction & Customer Details: Names, contact numbers, and purchase history of your customers, as well as invoice line-item descriptions, pricing, tax summaries, and dates.'),
                                            _buildSectionHeader(context, '2. How We Use Your Data'),
                                            _buildBulletPoint(context, 'Verify and authenticate user profiles via mobile phone OTP checks.'),
                                            _buildBulletPoint(context, 'Automate professional document rendering (PDF construction of invoices, quotations, purchase orders, credit notes, and Challans).'),
                                            _buildBulletPoint(context, 'Sync ledger statements, customer ledgers, and inventory/product catalogs safely with secure cloud repositories.'),
                                            _buildBulletPoint(context, 'Improve application performance, load times, and error reporting.'),
                                            _buildSectionHeader(context, '3. Data Storage & Security'),
                                            _buildParagraph(context, 'We deploy standard security protocols to safeguard your business logs. Authentication tokens are securely persisted locally using modern secure hardware storage (KeyStore on Android / Keychain on iOS) and synced over encrypted TLS layers to MongoDB servers. Your business documents are rendered sandbox-side and cataloged under your explicit user ID.'),
                                            _buildSectionHeader(context, '4. Third-Party Integrations'),
                                            _buildBulletPoint(context, 'Firebase Authentication: Manages secure mobile verification codes and tokens.'),
                                            _buildBulletPoint(context, 'Railway Cloud Platform: Secures and runs backend microservices.'),
                                            _buildSectionHeader(context, '5. Your Rights & Data Deletion'),
                                            _buildParagraph(context, 'You have full ownership of your data. You can inspect, modify, or completely delete your Business Profile, Customer logs, and catalog entries from the app settings, or request permanent deletion of your Firebase user authentication account by contacting our support team at support@getzio.in.'),
                                          ],
                                        );
                                      },
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicySheet(String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: children,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
