import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/analytics_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _prefKey = 'nestora_theme_mode';
  final AnalyticsService? analyticsService;

  ThemeCubit({this.analyticsService}) : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_prefKey);
      if (modeString != null) {
        switch (modeString) {
          case 'dark':
            emit(ThemeMode.dark);
            break;
          case 'system':
            emit(ThemeMode.system);
            break;
          default:
            emit(ThemeMode.light);
        }
      }
    } catch (_) {
      // Fallback to default ThemeMode.light
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    analyticsService?.logThemeChanged(themeMode: mode.name);
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      if (mode == ThemeMode.system) val = 'system';
      await prefs.setString(_prefKey, val);
    } catch (_) {}
  }
}
