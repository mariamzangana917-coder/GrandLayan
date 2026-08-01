import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/grand_layan_app.dart';
import 'core/theme/theme_mode_notifier.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessagingService.initialize();
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessagingService.initialize();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
