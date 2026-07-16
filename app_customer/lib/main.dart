import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/grand_layan_app.dart';
import 'core/theme/theme_mode_notifier.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /*
   * إبقاء شاشة الـ Native Splash ظاهرة إلى أن نقرأ
   * الوضع المحفوظ ونجهز أول واجهة بدون وميض أبيض أو أسود.
   */
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  const secureStorage = FlutterSecureStorage();

  final savedTheme = await secureStorage.read(
    key: ThemeModeNotifier.storageKey,
  );

  final initialThemeMode = savedTheme == 'dark'
      ? ThemeMode.dark
      : ThemeMode.light;

  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(initialThemeMode)],
      child: const GrandLayanApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}
