import 'package:go_router/go_router.dart';
import '../../features/account/presentation/pages/privacy_security_page.dart';
import '../../features/auth/presentation/customer_auth_gate.dart';
import '../../features/auth/presentation/customer_login_page.dart';
import '../../features/auth/presentation/customer_register_page.dart';
import '../../features/auth/presentation/welcome_page.dart';
import '../../features/chat/presentation/grand_layan_chat_page.dart';
import '../../features/clinic/presentation/clinic_page.dart';
import '../../features/main/presentation/customer_main_shell.dart';
import '../../features/salon/presentation/salon_page.dart';
import '../../features/appointments/presentation/booking_page.dart';
import '../../features/catalog/data/models/catalog_item.dart';
import 'package:flutter/material.dart';
import '../../features/appointments/data/models/customer_appointment.dart';
import '../../features/appointments/presentation/customer_appointment_details_page.dart';
import '../../features/appointments/presentation/customer_appointments_page.dart';
import '../../features/gift_cards/presentation/customer_gift_cards_page.dart';
import '../../features/offers/presentation/offers_page.dart';

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

      GoRoute(
        path: '/clinic',
        name: 'clinic',
        builder: (context, state) {
          return const ClinicPage();
        },
      ),

      GoRoute(
        path: '/offers',
        name: 'offers',
        builder: (context, state) {
          final String? department = state.uri.queryParameters['department'];

          return OffersPage(department: department);
        },
      ),

      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          final Object? extra = state.extra;

          if (extra is! CatalogItem) {
            return const Scaffold(
              body: Center(child: Text('تعذر فتح صفحة الحجز.')),
            );
          }

          return BookingPage(item: extra);
        },
      ),

      GoRoute(
        path: '/appointments',
        name: 'customer-appointments',
        builder: (context, state) {
          return const CustomerAppointmentsPage();
        },
      ),

      GoRoute(
        path: '/appointments/:id',
        name: 'customer-appointment-details',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final extra = state.extra is CustomerAppointment
              ? state.extra as CustomerAppointment
              : null;
          return CustomerAppointmentDetailsPage(
            appointmentId: id,
            initialAppointment: extra,
          );
        },
      ),

      GoRoute(
        path: '/gift-cards',
        name: 'gift-cards',
        builder: (context, state) {
          return const CustomerGiftCardsPage();
        },
      ),

      GoRoute(
        path: '/privacy-security',
        name: 'privacy-security',
        builder: (context, state) {
          return const PrivacySecurityPage();
        },
      ),

      GoRoute(
        path: '/ask-grand-layan',
        name: 'ask-grand-layan',
        builder: (context, state) {
          return const GrandLayanChatPage();
        },
      ),
    ],

    errorBuilder: (context, state) {
      return const CustomerAuthGate();
    },
  );

  const AppRouter._();
}
