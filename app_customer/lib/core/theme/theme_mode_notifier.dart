import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String storageKey = 'theme_mode';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    return ref.watch(initialThemeModeProvider);
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    state = newMode;

    await _storage.write(
      key: storageKey,
      value: newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> setLight() async {
    state = ThemeMode.light;

    await _storage.write(key: storageKey, value: 'light');
  }

  Future<void> setDark() async {
    state = ThemeMode.dark;

    await _storage.write(key: storageKey, value: 'dark');
  }
}
