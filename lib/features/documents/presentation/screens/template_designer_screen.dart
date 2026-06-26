import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/features/documents/presentation/providers/document_templates_provider.dart';

class TemplateDesignerScreen extends ConsumerStatefulWidget {
  const TemplateDesignerScreen({super.key});

  @override
  ConsumerState<TemplateDesignerScreen> createState() => _TemplateDesignerScreenState();
}

class _TemplateDesignerScreenState extends ConsumerState<TemplateDesignerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Custom Template');
  String _layout = 'modern';
  String _themeColor = '#2563EB';
  String _paperSize = 'A4';
  String _orientation = 'portrait';
  bool _showLogo = true;
  bool _showSignature = true;
  bool _showStamp = false;
  bool _showQrCode = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newTemplate = DocumentTemplateModel(
          id: '',
          name: _nameController.text.trim(),
          layout: _layout,
          themeColor: _themeColor,
          textColor: '#1E293B',
          fontFamily: 'Inter',
          fontSize: 10,
          showLogo: _showLogo,
          showSignature: _showSignature,
          showStamp: _showStamp,
          showQrCode: _showQrCode,
          paperSize: _paperSize,
          orientation: _orientation,
          isDefault: true,
        );

        await ref.read(documentTemplatesProvider.notifier).createTemplate(newTemplate);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template designed and saved successfully!')),
          );
        }
      } catch (e) {
        // Handled in state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Designer'),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Template Name *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 18),

                    // Layout Selection
                    DropdownButtonFormField<String>(
                      value: _layout,
                      decoration: const InputDecoration(labelText: 'Layout Style'),
                      items: const [
                        DropdownMenuItem(value: 'modern', child: Text('Modern Minimal')),
                        DropdownMenuItem(value: 'minimal', child: Text('Clean Minimal')),
                        DropdownMenuItem(value: 'classic', child: Text('Classic Retro')),
                        DropdownMenuItem(value: 'corporate', child: Text('Corporate Bold')),
                      ],
                      onChanged: (val) => setState(() => _layout = val!),
                    ),
                    const SizedBox(height: 18),

                    // Colors Selector
                    const Text('Theme Colors', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildColorBubble('#2563EB', Colors.blue),
                        _buildColorBubble('#10B981', Colors.green),
                        _buildColorBubble('#F59E0B', Colors.amber),
                        _buildColorBubble('#EF4444', Colors.red),
                        _buildColorBubble('#7C3AED', Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Toggles for Logo, Signature, Stamp, Qr
                    SwitchListTile(
                      title: const Text('Show Company Logo'),
                      value: _showLogo,
                      onChanged: (val) => setState(() => _showLogo = val),
                    ),
                    SwitchListTile(
                      title: const Text('Show Signatory Line'),
                      value: _showSignature,
                      onChanged: (val) => setState(() => _showSignature = val),
                    ),
                    SwitchListTile(
                      title: const Text('Show Digital Stamp'),
                      value: _showStamp,
                      onChanged: (val) => setState(() => _showStamp = val),
                    ),
                    SwitchListTile(
                      title: const Text('Show Payment QR Code'),
                      value: _showQrCode,
                      onChanged: (val) => setState(() => _showQrCode = val),
                    ),
                  ],
                ),
              ),

              // Save button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveTemplate,
                  child: const Text('Apply Template Changes'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorBubble(String hex, Color color) {
    final isSelected = _themeColor == hex;
    return GestureDetector(
      onTap: () => setState(() => _themeColor = hex),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 6)] : null,
        ),
      ),
    );
  }
}
