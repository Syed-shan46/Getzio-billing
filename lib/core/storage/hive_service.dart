import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  static const String _preferencesBox = 'preferencesBox';
  static const String _cacheBox = 'cacheBox';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_preferencesBox);
    await Hive.openBox(_cacheBox);
  }

  // Example generic methods
  Future<void> savePreference(String key, dynamic value) async {
    final box = Hive.box(_preferencesBox);
    await box.put(key, value);
  }

  dynamic getPreference(String key, {dynamic defaultValue}) {
    final box = Hive.box(_preferencesBox);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> saveCache(String key, dynamic value) async {
    final box = Hive.box(_cacheBox);
    await box.put(key, value);
  }

  dynamic getCache(String key) {
    final box = Hive.box(_cacheBox);
    return box.get(key);
  }

  Future<void> clearCache() async {
    final box = Hive.box(_cacheBox);
    await box.clear();
  }
}
