import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/auth_session.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final AuthSession _authSession = AuthSession();

  ThemeMode _themeMode = ThemeMode.light;

  bool get _isDarkMode => _themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();

    _authSession.addListener(_refresh);
    _authSession.initialize();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _isDarkMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  void dispose() {
    _authSession.removeListener(_refresh);
    _authSession.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grand Layan Admin',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: _themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB89552),
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB89552),
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
      ),

      home: switch (_authSession.status) {
        AuthStatus.checking => _SessionCheckingScreen(isDarkMode: _isDarkMode),

        AuthStatus.authenticated => DashboardScreen(
          authSession: _authSession,
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
        ),

        AuthStatus.unauthenticated => LoginScreen(
          authSession: _authSession,
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
        ),
      },
    );
  }
}

class _SessionCheckingScreen extends StatelessWidget {
  const _SessionCheckingScreen({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Container(
          color: backgroundColor,
          child: Image.asset(
            isDarkMode
                ? 'assets/images/logo_dark.jpg'
                : 'assets/images/logo_light.jpg',
            width: 180,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
