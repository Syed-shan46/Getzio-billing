import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:getzio_billing/features/company/data/models/company_model.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';
import '../providers/company_provider.dart';

class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _gstController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Address
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  // Bank Details
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _branchController = TextEditingController();

  // Branding and Customization
  String? _logoBase64;
  String? _signatureBase64;
  String? _stampBase64;
  String _selectedTemplate = 'modern';

  String? _logoFileName;
  String? _signatureFileName;
  String? _stampFileName;

  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final company = ref.read(companyProvider).value;
      if (company != null) {
        setState(() {
          _isEditMode = true;
          _nameController.text = company.companyName;
          _gstController.text = company.gstNumber ?? '';
          _phoneController.text = company.phone ?? '';
          _emailController.text = company.email ?? '';
          _websiteController.text = company.website ?? '';
          _streetController.text = company.address.street ?? '';
          _cityController.text = company.address.city ?? '';
          _stateController.text = company.address.state ?? '';
          _zipController.text = company.address.zipCode ?? '';
          _countryController.text = company.address.country;
          _bankNameController.text = company.bankDetails.bankName ?? '';
          _accountNoController.text = company.bankDetails.accountNumber ?? '';
          _ifscController.text = company.bankDetails.ifscCode ?? '';
          _branchController.text = company.bankDetails.branchAddress ?? '';
          _selectedTemplate = company.defaultTemplate;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gstController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = 'data:image/png;base64,${base64Encode(bytes)}';
        setState(() {
          if (type == 'logo') {
            _logoBase64 = base64Str;
            _logoFileName = image.name;
          } else if (type == 'signature') {
            _signatureBase64 = base64Str;
            _signatureFileName = image.name;
          } else if (type == 'stamp') {
            _stampBase64 = base64Str;
            _stampFileName = image.name;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final address = CompanyAddress(
        street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
        country: _countryController.text.trim(),
      );

      final bankDetails = BankDetails(
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        accountNumber: _accountNoController.text.trim().isEmpty ? null : _accountNoController.text.trim(),
        ifscCode: _ifscController.text.trim().isEmpty ? null : _ifscController.text.trim(),
        branchAddress: _branchController.text.trim().isEmpty ? null : _branchController.text.trim(),
      );

      await ref.read(companyProvider.notifier).saveCompany(
        companyName: _nameController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim().toUpperCase(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        address: address,
        bankDetails: bankDetails,
        logoBase64: _logoBase64,
        signatureBase64: _signatureBase64,
        stampBase64: _stampBase64,
        defaultTemplate: _selectedTemplate,
      );

      if (_isEditMode && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile updated successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile created successfully!')),
        );
        context.go('/success');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyProvider);
    final company = companyState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(companyProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });

    final isLoading = companyState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Business Profile' : 'Setup Business Profile'),
        leading: _isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  children: [
                    Text(
                      _isEditMode
                          ? 'Update your brand identity, contact, address, and banking coordinates.'
                          : 'Create your Business Profile to start creating professional documents and managing bills.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // --- Branding Customization Section ---
                    _buildSectionTitle(context, 'Branding & Style'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedTemplate,
                              decoration: const InputDecoration(
                                labelText: 'Default PDF Template *',
                                prefixIcon: Icon(Icons.palette_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'modern', child: Text('Modern Layout (Default)')),
                                DropdownMenuItem(value: 'minimal', child: Text('Minimal Clean')),
                                DropdownMenuItem(value: 'classic', child: Text('Classic Formal')),
                                DropdownMenuItem(value: 'corporate', child: Text('Corporate Professional')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedTemplate = val);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAssetPicker(
                                    title: 'Company Logo',
                                    imageUrl: company?.logoUrl,
                                    base64Data: _logoBase64,
                                    fileName: _logoFileName,
                                    onTap: () => _pickImage('logo'),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildAssetPicker(
                                    title: 'Authorized Signature',
                                    imageUrl: company?.signatureUrl,
                                    base64Data: _signatureBase64,
                                    fileName: _signatureFileName,
                                    onTap: () => _pickImage('signature'),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAssetPicker(
                                    title: 'Stamp (Optional)',
                                    imageUrl: company?.stampUrl,
                                    base64Data: _stampBase64,
                                    fileName: _stampFileName,
                                    onTap: () => _pickImage('stamp'),
                                    isDark: isDark,
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Basic Info Section ---
                    _buildSectionTitle(context, 'Basic Information'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name *',
                                hintText: 'e.g. Getzio Technologies',
                                prefixIcon: Icon(Icons.business_outlined, size: 20),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Company name is required' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _gstController,
                              decoration: const InputDecoration(
                                labelText: 'GST Number (Optional)',
                                hintText: 'e.g. 27AAAAA1111A1Z1',
                                prefixIcon: Icon(Icons.percent_outlined, size: 20),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final regex = RegExp(
                                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                                  if (!regex.hasMatch(value.trim())) {
                                    return 'Enter a valid GST number';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone',
                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Contact Email',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                prefixIcon: Icon(Icons.language_outlined, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Address Section ---
                    _buildSectionTitle(context, 'Business Address'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _streetController,
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(labelText: 'City'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stateController,
                                    decoration: const InputDecoration(labelText: 'State'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _zipController,
                                    decoration: const InputDecoration(labelText: 'Zip/Postal Code'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _countryController,
                                    decoration: const InputDecoration(labelText: 'Country'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Bank Details Section ---
                    _buildSectionTitle(context, 'Bank Accounts (Optional)'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'Bank Name',
                                prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _accountNoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Account Number',
                                prefixIcon: Icon(Icons.payment_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _ifscController,
                              decoration: const InputDecoration(
                                labelText: 'IFSC Code',
                                prefixIcon: Icon(Icons.code_rounded, size: 20),
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _branchController,
                              decoration: const InputDecoration(
                                labelText: 'Branch Address',
                                prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Save button persistent footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_isEditMode ? 'Update Business Profile' : 'Save and Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildAssetPicker({
    required String title,
    String? imageUrl,
    String? base64Data,
    String? fileName,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    ImageProvider? imageProvider;
    if (base64Data != null) {
      final base64String = base64Data.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64String));
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (imageProvider != null)
                Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              if (imageProvider != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (fileName != null)
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fileName,
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
