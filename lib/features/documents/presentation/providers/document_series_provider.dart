import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/core/network/dio_client.dart';

class DocumentSeriesModel {
  final String id;
  final String documentType;
  final String name;
  final String prefix;
  final String suffix;
  final int padding;
  final int nextNumber;
  final bool resetEveryYear;
  final String financialYear;
  final bool isActive;

  DocumentSeriesModel({
    required this.id,
    required this.documentType,
    required this.name,
    required this.prefix,
    required this.suffix,
    required this.padding,
    required this.nextNumber,
    required this.resetEveryYear,
    required this.financialYear,
    required this.isActive,
  });

  factory DocumentSeriesModel.fromJson(Map<String, dynamic> json) {
    return DocumentSeriesModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      prefix: json['prefix'] as String? ?? '',
      suffix: json['suffix'] as String? ?? '',
      padding: json['padding'] as int? ?? 6,
      nextNumber: json['nextNumber'] as int? ?? 1,
      resetEveryYear: json['resetEveryYear'] as bool? ?? true,
      financialYear: json['financialYear'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'name': name,
      'prefix': prefix,
      'suffix': suffix,
      'padding': padding,
      'nextNumber': nextNumber,
      'resetEveryYear': resetEveryYear,
      'financialYear': financialYear,
      'isActive': isActive,
    };
  }
}

class DocumentSeriesNotifier extends AsyncNotifier<List<DocumentSeriesModel>> {
  @override
  FutureOr<List<DocumentSeriesModel>> build() async {
    return _fetchSeries();
  }

  Future<List<DocumentSeriesModel>> _fetchSeries() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/billing/documents/series');
      if (response.statusCode == 200) {
        final data = response.data['data']['series'] as List;
        return data.map((s) => DocumentSeriesModel.fromJson(s as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  Future<void> createSeries(DocumentSeriesModel series) async {
    state = const AsyncValue.loading();
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/billing/documents/series', data: series.toJson());
      state = await AsyncValue.guard(() => _fetchSeries());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final documentSeriesProvider = AsyncNotifierProvider<DocumentSeriesNotifier, List<DocumentSeriesModel>>(DocumentSeriesNotifier.new);
