import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/gift_card_design.dart';
import '../data/services/customer_gift_cards_api.dart';

class PurchaseGiftCardPage extends StatefulWidget {
  const PurchaseGiftCardPage({required this.design, super.key});

  final GiftCardDesign design;

  @override
  State<PurchaseGiftCardPage> createState() => _PurchaseGiftCardPageState();
}

class _PurchaseGiftCardPageState extends State<PurchaseGiftCardPage> {
  static const Color _gold = Color(0xFFC9A227);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CustomerGiftCardsApi _api = CustomerGiftCardsApi();

  final TextEditingController _recipientNameController =
      TextEditingController();

  final TextEditingController _recipientPhoneController =
      TextEditingController();

  final TextEditingController _giftMessageController = TextEditingController();

  String _paymentMethod = 'cash';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await _api.createOrder(
        giftCardDesignId: widget.design.id,
        recipientName: _recipientNameController.text,
        recipientPhone: _recipientPhoneController.text,
        giftMessage: _giftMessageController.text,
        paymentMethod: _paymentMethod,
      );

      if (!mounted) {
        return;
      }

      final orderId = order['id'];

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              icon: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF22C55E),
                  size: 39,
                ),
              ),
              title: const Text(
                'تم إرسال طلبك',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Text(
                orderId == null
                    ? 'تم إنشاء طلب بطاقة الهدية بنجاح، وهو الآن بانتظار التأكيد.'
                    : 'رقم الطلب: #$orderId\nتم إنشاء الطلب بنجاح، وهو الآن بانتظار التأكيد.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.7),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'تم',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on CustomerGiftCardsException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError('حدث خطأ غير متوقع أثناء إنشاء الطلب.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final primaryTextColor = isDark
        ? const Color(0xFFEAEAEA)
        : const Color(0xFF1C1C1C);

    final secondaryTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'شراء بطاقة هدية',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    _SelectedGiftCard(
                      design: widget.design,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(height: 14),
                    _FormCard(
                      title: 'بيانات المستلمة',
                      icon: Icons.person_outline_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _recipientNameController,
                            textInputAction: TextInputAction.next,
                            maxLength: 255,
                            decoration: _inputDecoration(
                              label: 'اسم المستلمة *',
                              icon: Icons.person_outline_rounded,
                              borderColor: borderColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'اكتبي اسم المستلمة.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _recipientPhoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            decoration: _inputDecoration(
                              label: 'رقم هاتف المستلمة *',
                              icon: Icons.phone_outlined,
                              borderColor: borderColor,
                              secondaryTextColor: secondaryTextColor,
                            ).copyWith(hintText: '07XXXXXXXXX'),
                            validator: (value) {
                              final phone = value?.trim() ?? '';

                              if (phone.isEmpty) {
                                return 'رقم هاتف المستلمة مطلوب';
                              }

                              if (!RegExp(r'^07\d{9}$').hasMatch(phone)) {
                                return 'أدخلي رقمًا عراقيًا صحيحًا يبدأ بـ 07';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _giftMessageController,
                            minLines: 3,
                            maxLines: 5,
                            maxLength: 1000,
                            decoration: _inputDecoration(
                              label: 'رسالة الهدية (اختيارية)',
                              icon: Icons.mail_outline_rounded,
                              borderColor: borderColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormCard(
                      title: 'طريقة الدفع',
                      icon: Icons.payments_outlined,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      child: Column(
                        children: [
                          _PaymentOption(
                            title: 'الدفع عند الوصول',
                            subtitle: 'يتم دفع قيمة البطاقة في المركز.',
                            icon: Icons.payments_rounded,
                            value: 'cash',
                            selectedValue: _paymentMethod,
                            borderColor: borderColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _PaymentOption(
                            title: 'الدفع الإلكتروني',
                            subtitle:
                                'يتم استكمال الدفع الإلكتروني بعد إنشاء الطلب.',
                            icon: Icons.credit_card_rounded,
                            value: 'electronic',
                            selectedValue: _paymentMethod,
                            borderColor: borderColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _gold.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.3,
                              ),
                            )
                          : Text(
                              'شراء ',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color borderColor,
    required Color secondaryTextColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _gold),
      counterText: '',
      labelStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

class _SelectedGiftCard extends StatelessWidget {
  const _SelectedGiftCard({
    required this.design,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  static const Color _gold = Color(0xFFC9A227);

  final GiftCardDesign design;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _LargeGiftCardImage(imageUrl: design.imageUrl),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            design.name,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 7),
          Text(
            design.formattedAmount,
            style: const TextStyle(
              color: _gold,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          Divider(color: _gold.withOpacity(.18), height: 1),

          const SizedBox(height: 12),

          if (design.description != null) ...[
            const SizedBox(height: 8),
            Text(
              design.description!,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ],
          if (design.validityDays != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 17, color: _gold),
                const SizedBox(width: 6),
                Text(
                  'صالحة لمدة ${design.validityDays} يوم',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LargeGiftCardImage extends StatelessWidget {
  const _LargeGiftCardImage({required this.imageUrl});

  static const Color _gold = Color(0xFFC9A227);

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF8D9), Color(0xFFE9D589)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.card_giftcard_rounded, color: _gold, size: 60),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.child,
  });

  static const Color _gold = Color(0xFFC9A227);

  final String title;
  final IconData icon;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _gold, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onChanged,
  });

  static const Color _gold = Color(0xFFC9A227);

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String selectedValue;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _gold.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _gold : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              activeColor: _gold,
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
            Icon(icon, color: selected ? _gold : secondaryTextColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
