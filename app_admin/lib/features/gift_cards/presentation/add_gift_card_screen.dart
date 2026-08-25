import 'package:flutter/material.dart';

import '../data/gift_card.dart';
import '../data/gift_card_service.dart';
import '../widgets/gift_card_form.dart';

class AddGiftCardScreen extends StatefulWidget {
  const AddGiftCardScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AddGiftCardScreen> createState() => _AddGiftCardScreenState();
}

class _AddGiftCardScreenState extends State<AddGiftCardScreen> {
  final GiftCardService _service = const GiftCardService();

  Future<void> _createGiftCard(GiftCardFormData data) async {
    try {
      final created = await _service.createGiftCard(
        name: data.name,
        description: data.description,
        amount: data.amount,
        validityDays: data.validityDays,
        isActive: data.isActive,
        sortOrder: data.sortOrder,
        imageFilePath: data.imageFilePath,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<GiftCard>(created);
    } on GiftCardException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('حدث خطأ غير متوقع أثناء إضافة البطاقة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
    final primaryTextColor = widget.isDarkMode
        ? const Color(0xFFEAEAEA)
        : const Color(0xFF1C1C1C);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: 19,
          ),
        ),
        title: Text(
          'إضافة بطاقة هدية',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: GiftCardForm(
            isDarkMode: widget.isDarkMode,
            onSubmit: _createGiftCard,
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
