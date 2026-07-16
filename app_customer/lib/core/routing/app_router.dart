import 'package:go_router/go_router.dart';
import '../../features/clinic/presentation/clinic_page.dart';
import '../../features/auth/presentation/customer_auth_gate.dart';
import '../../features/auth/presentation/customer_login_page.dart';
import '../../features/auth/presentation/customer_register_page.dart';
import '../../features/auth/presentation/welcome_page.dart';
import '../../features/salon/presentation/salon_page.dart';
import '../../features/main/presentation/customer_main_shell.dart';


abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',

    routes: [
      GoRoute(
        path: '/',
        name: 'auth-gate',
        builder: (context, state) {
          return const CustomerAuthGate();
        },
      ),

      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) {
          return const WelcomePage();
        },
      ),

      GoRoute(
        path: '/customer/login',
        name: 'customer-login',
        builder: (context, state) {
          return const CustomerLoginPage();
        },
      ),
      GoRoute(
        path: '/clinic',
        name: 'clinic',
        builder: (context, state) {
          return const ClinicPage();
        },
      ),
      GoRoute(
        path: '/customer/register',
        name: 'customer-register',
        builder: (context, state) {
          return const CustomerRegisterPage();
        },
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          return const CustomerMainShell();
        },
      ),

      GoRoute(
        path: '/salon',
        name: 'salon',
        builder: (context, state) {
          return const SalonPage();
        },
      ),
    ],

    errorBuilder: (context, state) {
      return const CustomerAuthGate();
    },
  );

  const AppRouter._();
}
