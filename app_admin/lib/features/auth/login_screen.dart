import 'package:flutter/material.dart';

import 'auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authSession,
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  final AuthSession authSession;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _loginController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await widget.authSession.login(
      login: _loginController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    final secondaryTextColor = isDarkMode
        ? const Color(0xFFBDBDBD)
        : const Color(0xFF777777);

    final fieldColor = isDarkMode
        ? const Color(0xFF111111)
        : const Color(0xFFF8F8F8);

    final fieldBorderColor = isDarkMode
        ? const Color(0xFF303030)
        : const Color(0xFFE7E7E7);

    final logoPath = isDarkMode
        ? 'assets/images/logo_dark.jpg'
        : 'assets/images/logo_light.jpg';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 14,
                child: IconButton(
                  onPressed: widget.onToggleTheme,
                  tooltip: isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isDarkMode
                          ? Icons.wb_sunny_outlined
                          : Icons.dark_mode_outlined,
                      key: ValueKey<bool>(isDarkMode),
                      color: isDarkMode
                          ? const Color(0xFFD8B56A)
                          : const Color(0xFF171717),
                      size: 27,
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            color: backgroundColor,
                            child: Image.asset(
                              logoPath,
                              width: 205,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'سجّلي الدخول لإدارة المركز',
                            style: TextStyle(
                              fontSize: 15,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 36),
                          TextFormField(
                            controller: _loginController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: primaryTextColor),
                            decoration: _fieldDecoration(
                              label: 'البريد الإلكتروني أو رقم الهاتف',
                              icon: Icons.person_outline,
                              fieldColor: fieldColor,
                              borderColor: fieldBorderColor,
                              textColor: secondaryTextColor,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'أدخلي البريد الإلكتروني أو رقم الهاتف.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(color: primaryTextColor),
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _submit();
                              }
                            },
                            decoration:
                                _fieldDecoration(
                                  label: 'كلمة المرور',
                                  icon: Icons.lock_outline,
                                  fieldColor: fieldColor,
                                  borderColor: fieldBorderColor,
                                  textColor: secondaryTextColor,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'أدخلي كلمة المرور.';
                              }

                              return null;
                            },
                          ),
                          if (widget.authSession.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF351414)
                                    : const Color(0xFFFFF1F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.authSession.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? const Color(0xFFFF9E9E)
                                      : const Color(0xFFB42318),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? const Color(0xFFD3B06B)
                                    : const Color(0xFF171717),
                                foregroundColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF777777,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 23,
                                      height: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required Color fieldColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor),
      prefixIcon: Icon(icon, color: textColor),
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB89552), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
    );
  }
}
