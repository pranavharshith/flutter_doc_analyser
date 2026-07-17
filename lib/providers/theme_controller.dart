import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/app_constants.dart';

/// Global theme state.
///
/// Load once at app start, wrap the tree with [ThemeScope], then read via
/// [ThemeScope.of] / [ThemeControllerX] — never pass `isDarkMode` as a prop.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _ready = false;

  ThemeMode get themeMode => _themeMode;
  bool get isReady => _ready;

  /// Whether the *effective* UI is dark (resolves [ThemeMode.system]).
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  /// Load prefs. Migrates legacy `isDarkMode` bool → `theme_mode` string.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.prefThemeMode);

    if (stored != null) {
      _themeMode = _parse(stored);
    } else {
      final legacy = prefs.getBool(AppConstants.prefDarkMode);
      if (legacy != null) {
        _themeMode = legacy ? ThemeMode.dark : ThemeMode.light;
        await prefs.setString(
          AppConstants.prefThemeMode,
          _serialize(_themeMode),
        );
      }
    }

    _ready = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, _serialize(mode));
    // Keep legacy key in sync for any external readers.
    if (mode != ThemeMode.system) {
      await prefs.setBool(AppConstants.prefDarkMode, mode == ThemeMode.dark);
    }
  }

  /// Flip between light and dark based on current *effective* brightness.
  Future<void> toggle(BuildContext context) async {
    final currentlyDark = isDark(context);
    await setThemeMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _parse(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }
}

/// Provides [ThemeController] to the widget tree via [InheritedNotifier].
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Watch (rebuilds when theme changes).
  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without registering a dependency (e.g. in callbacks).
  static ThemeController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.notifier!;
  }
}

/// Convenience accessors on [BuildContext].
extension ThemeControllerX on BuildContext {
  ThemeController get themeController => ThemeScope.of(this);

  /// Effective dark flag from Material [ThemeData] (preferred for colors).
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
