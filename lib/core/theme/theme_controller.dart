import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_app/core/theme/app_date_format.dart';
import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/app_bottom_navigation.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(
    this._prefs, {
    bool defaultOnboardingCompleted = true,
  }) : _defaultOnboardingCompleted = defaultOnboardingCompleted {
    _load();
  }

  final bool _defaultOnboardingCompleted;

  static const themeModeKey = 'app.themeMode';
  static const paletteIdKey = 'app.themePaletteId';
  static const customLightKey = 'app.customLightPalette';
  static const customDarkKey = 'app.customDarkPalette';
  static const photoPathKey = 'app.backgroundPhotoPath';
  static const photoDimmingKey = 'app.backgroundDimming';
  static const photoBlurKey = 'app.backgroundBlur';
  static const dateFormatKey = 'app.dateFormat';
  static const bottomNavStyleKey = 'navigation.bottom.style';
  static const bottomNavDestinationsKey = 'navigation.bottom.destinations';
  static const onboardingCompletedKey = 'app.onboardingCompleted';
  static const tourCompletedKey = 'app.learningTourCompleted';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String _paletteId = 'classic';
  AppThemePalette _customLight = AppTheme.classicLight;
  AppThemePalette _customDark = AppTheme.classicDark;
  String? _backgroundPhotoPath;
  double _backgroundDimming = 0.4;
  double _backgroundBlur = 0.0;
  AppDateFormat _dateFormat = AppDateFormat.automatic;
  BottomNavStyle _bottomNavStyle = BottomNavStyle.soft;
  List<BottomNavDestination> _bottomNavDestinations =
      AppBottomNavigation.defaultDestinations;
  bool _onboardingCompleted = true;
  bool _tourCompleted = true;

  ThemeMode get themeMode => _themeMode;
  String get paletteId => _paletteId;
  AppThemePalette get customLight => _customLight;
  AppThemePalette get customDark => _customDark;
  String? get backgroundPhotoPath => _backgroundPhotoPath;
  double get backgroundDimming => _backgroundDimming;
  double get backgroundBlur => _backgroundBlur;
  AppDateFormat get dateFormat => _dateFormat;
  BottomNavStyle get bottomNavStyle => _bottomNavStyle;
  List<BottomNavDestination> get bottomNavDestinations =>
      _bottomNavDestinations;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get tourCompleted => _tourCompleted;

  AppThemePalette get lightPalette {
    if (_paletteId == 'custom') return _customLight;
    return AppTheme.builtInLightPalettes[_paletteId] ?? AppTheme.classicLight;
  }

  AppThemePalette get darkPalette {
    if (_paletteId == 'custom') return _customDark;
    return AppTheme.builtInDarkPalettes[_paletteId] ?? AppTheme.classicDark;
  }

  void _load() {
    final stored = _prefs.getString(themeModeKey);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _paletteId = _prefs.getString(paletteIdKey) ?? 'classic';

    final rawLight = _prefs.getString(customLightKey);
    if (rawLight != null) {
      try {
        _customLight = AppThemePalette.fromJson(jsonDecode(rawLight));
      } catch (_) {}
    }
    final rawDark = _prefs.getString(customDarkKey);
    if (rawDark != null) {
      try {
        _customDark = AppThemePalette.fromJson(jsonDecode(rawDark));
      } catch (_) {}
    }

    _backgroundPhotoPath = _prefs.getString(photoPathKey);
    _backgroundDimming = (_prefs.getDouble(photoDimmingKey) ?? 0.4).clamp(
      0.0,
      1.0,
    );
    _backgroundBlur = (_prefs.getDouble(photoBlurKey) ?? 0.0).clamp(0.0, 20.0);
    _dateFormat = AppDateFormat.fromStorage(_prefs.getString(dateFormatKey));

    _bottomNavStyle = _prefs.getString(bottomNavStyleKey) == 'labels'
        ? BottomNavStyle.labels
        : BottomNavStyle.soft;
    if (_prefs.containsKey(bottomNavDestinationsKey)) {
      final rawDest =
          _prefs.getStringList(bottomNavDestinationsKey) ?? const [];
      final resolved = <BottomNavDestination>[];
      for (final name in rawDest) {
        for (final candidate in BottomNavDestination.values) {
          if (candidate.name == name && !resolved.contains(candidate)) {
            resolved.add(candidate);
          }
        }
      }
      _bottomNavDestinations = List.unmodifiable(resolved.take(5));
    }

    _onboardingCompleted =
        _prefs.getBool(onboardingCompletedKey) ?? _defaultOnboardingCompleted;
    _tourCompleted =
        _prefs.getBool(tourCompletedKey) ?? _defaultOnboardingCompleted;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(themeModeKey, raw);
    notifyListeners();
  }

  Future<void> setPaletteId(String id) async {
    if (_paletteId == id) return;
    _paletteId = id;
    await _prefs.setString(paletteIdKey, id);
    notifyListeners();
  }

  Future<bool> saveCustomPalettes({
    required Map<String, String> lightHex,
    required Map<String, String> darkHex,
  }) async {
    try {
      final parsedLight = AppThemePalette.fromJson(lightHex);
      final parsedDark = AppThemePalette.fromJson(darkHex);
      _customLight = parsedLight;
      _customDark = parsedDark;
      _paletteId = 'custom';
      await _prefs.setString(customLightKey, jsonEncode(parsedLight.toJson()));
      await _prefs.setString(customDarkKey, jsonEncode(parsedDark.toJson()));
      await _prefs.setString(paletteIdKey, 'custom');
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetCustomToClassic() async {
    _customLight = AppTheme.classicLight;
    _customDark = AppTheme.classicDark;
    _backgroundPhotoPath = null;
    _backgroundDimming = 0.4;
    _backgroundBlur = 0.0;
    await _prefs.remove(customLightKey);
    await _prefs.remove(customDarkKey);
    await _prefs.remove(photoPathKey);
    await _prefs.remove(photoDimmingKey);
    await _prefs.remove(photoBlurKey);
    notifyListeners();
  }

  Future<void> setPhotoBackground({
    String? path,
    bool clearPath = false,
    double? dimming,
    double? blur,
  }) async {
    if (clearPath) {
      _backgroundPhotoPath = null;
      await _prefs.remove(photoPathKey);
    } else if (path != null) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) {
        _backgroundPhotoPath = null;
        await _prefs.remove(photoPathKey);
      } else {
        _backgroundPhotoPath = trimmed;
        await _prefs.setString(photoPathKey, trimmed);
      }
    }
    if (dimming != null) {
      _backgroundDimming = dimming.clamp(0.0, 1.0);
      await _prefs.setDouble(photoDimmingKey, _backgroundDimming);
    }
    if (blur != null) {
      _backgroundBlur = blur.clamp(0.0, 20.0);
      await _prefs.setDouble(photoBlurKey, _backgroundBlur);
    }
    notifyListeners();
  }

  Future<void> setDateFormat(AppDateFormat format) async {
    if (_dateFormat == format) return;
    _dateFormat = format;
    await _prefs.setString(dateFormatKey, format.storageValue);
    notifyListeners();
  }

  Future<void> saveBottomNav({
    required BottomNavStyle style,
    required List<BottomNavDestination> destinations,
  }) async {
    final unique = <BottomNavDestination>[];
    for (final d in destinations) {
      if (!unique.contains(d)) unique.add(d);
    }
    _bottomNavStyle = style;
    _bottomNavDestinations = List.unmodifiable(unique.take(5));
    await _prefs.setString(
      bottomNavStyleKey,
      style == BottomNavStyle.labels ? 'labels' : 'soft',
    );
    await _prefs.setStringList(
      bottomNavDestinationsKey,
      _bottomNavDestinations.map((d) => d.name).toList(growable: false),
    );
    notifyListeners();
  }

  Future<void> resetBottomNavDefaults() async {
    await saveBottomNav(
      style: BottomNavStyle.soft,
      destinations: AppBottomNavigation.defaultDestinations,
    );
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _onboardingCompleted = completed;
    await _prefs.setBool(onboardingCompletedKey, completed);
    notifyListeners();
  }

  Future<void> setTourCompleted(bool completed) async {
    _tourCompleted = completed;
    await _prefs.setBool(tourCompletedKey, completed);
    notifyListeners();
  }
}
