import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/core/network/dio_client.dart';

class DocumentTemplateModel {
  final String id;
  final String name;
  final String layout;
  final String themeColor;
  final String textColor;
  final String fontFamily;
  final double fontSize;
  final bool showLogo;
  final bool showSignature;
  final bool showStamp;
  final bool showQrCode;
  final String paperSize;
  final String orientation;
  final String? headerText;
  final String? footerText;
  final bool isDefault;

  DocumentTemplateModel({
    required this.id,
    required this.name,
    required this.layout,
    required this.themeColor,
    required this.textColor,
    required this.fontFamily,
    required this.fontSize,
    required this.showLogo,
    required this.showSignature,
    required this.showStamp,
    required this.showQrCode,
    required this.paperSize,
    required this.orientation,
    this.headerText,
    this.footerText,
    required this.isDefault,
  });

  factory DocumentTemplateModel.fromJson(Map<String, dynamic> json) {
    return DocumentTemplateModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      layout: json['layout'] as String? ?? 'modern',
      themeColor: json['themeColor'] as String? ?? '#2563EB',
      textColor: json['textColor'] as String? ?? '#1E293B',
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 10.0,
      showLogo: json['showLogo'] as bool? ?? true,
      showSignature: json['showSignature'] as bool? ?? true,
      showStamp: json['showStamp'] as bool? ?? false,
      showQrCode: json['showQrCode'] as bool? ?? true,
      paperSize: json['paperSize'] as String? ?? 'A4',
      orientation: json['orientation'] as String? ?? 'portrait',
      headerText: json['headerText'] as String?,
      footerText: json['footerText'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'layout': layout,
      'themeColor': themeColor,
      'textColor': textColor,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'showLogo': showLogo,
      'showSignature': showSignature,
      'showStamp': showStamp,
      'showQrCode': showQrCode,
      'paperSize': paperSize,
      'orientation': orientation,
      'headerText': headerText,
      'footerText': footerText,
      'isDefault': isDefault,
    };
  }
}

class DocumentTemplatesNotifier extends AsyncNotifier<List<DocumentTemplateModel>> {
  @override
  FutureOr<List<DocumentTemplateModel>> build() async {
    return _fetchTemplates();
  }

  Future<List<DocumentTemplateModel>> _fetchTemplates() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/documents/templates');
      if (response.statusCode == 200) {
        final data = response.data['data']['templates'] as List;
        return data.map((t) => DocumentTemplateModel.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  Future<void> createTemplate(DocumentTemplateModel template) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/billing/documents/templates', data: template.toJson());
      state = await AsyncValue.guard(() => _fetchTemplates());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final documentTemplatesProvider = AsyncNotifierProvider<DocumentTemplatesNotifier, List<DocumentTemplateModel>>(DocumentTemplatesNotifier.new);
