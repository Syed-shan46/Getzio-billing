import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getzio_billing/core/storage/hive_service.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final HiveService _hiveService;
  static const String _themeKey = 'selected_theme_mode';

  ThemeModeNotifier(this._hiveService) : super(ThemeMode.system) {
    final storedIndex = _hiveService.getPreference(_themeKey, defaultValue: -1);
    if (storedIndex >= 0 && storedIndex < ThemeMode.values.length) {
      state = ThemeMode.values[storedIndex];
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _hiveService.savePreference(_themeKey, mode.index);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return ThemeModeNotifier(hive);
});
