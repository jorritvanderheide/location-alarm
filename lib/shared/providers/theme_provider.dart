import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/providers/preferences_provider.dart';

const _themeKey = 'theme_mode';
const _amoledKey = 'amoled_black';
const _materialYouKey = 'material_you';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final amoledBlackProvider = NotifierProvider<AmoledBlackNotifier, bool>(
  AmoledBlackNotifier.new,
);

final materialYouProvider = NotifierProvider<MaterialYouNotifier, bool>(
  MaterialYouNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(preferencesProvider);
    final stored = prefs.getString(_themeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void set(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(preferencesProvider);
    prefs.setString(_themeKey, mode.name);
  }
}

class MaterialYouNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(preferencesProvider);
    return prefs.getBool(_materialYouKey) ?? false;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs.setBool(_materialYouKey, enabled);
  }
}

class AmoledBlackNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(preferencesProvider);
    return prefs.getBool(_amoledKey) ?? false;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs.setBool(_amoledKey, enabled);
  }
}
