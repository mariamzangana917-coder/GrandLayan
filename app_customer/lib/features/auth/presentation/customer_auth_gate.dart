import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main/presentation/customer_main_shell.dart';
import '../providers/customer_auth_provider.dart';
import 'welcome_page.dart';

class CustomerAuthGate extends ConsumerWidget {
  const CustomerAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(customerAuthProvider);

    return authState.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      data: (customer) {
        if (customer == null) {
          return const WelcomePage();
        }

        return const CustomerMainShell();
      },
      error: (error, stackTrace) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 52),
                    const SizedBox(height: 18),
                    const Text(
                      'تعذر التحقق من جلسة تسجيل الدخول.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'تأكدي من تشغيل الخادم واتصال الهاتف بالشبكة.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(customerAuthProvider.notifier)
                            .refreshSession();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
