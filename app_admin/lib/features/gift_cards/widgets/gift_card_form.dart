import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GiftCardFormData {
  const GiftCardFormData({
    required this.name,
    required this.amount,
    required this.validityDays,
    required this.isActive,
    required this.sortOrder,
    this.description,
    this.imageFilePath,
  });

  final String name;
  final String? description;
  final int amount;
  final int validityDays;
  final bool isActive;
  final int sortOrder;
  final String? imageFilePath;
}

class GiftCardForm extends StatefulWidget {
  const GiftCardForm({
    required this.isDarkMode,
    required this.onSubmit,
    this.initialData,
    this.submitLabel = 'حفظ بطاقة الهدية',
    super.key,
  });

  final bool isDarkMode;
  final Future<void> Function(GiftCardFormData data) onSubmit;
  final GiftCardFormData? initialData;
  final String submitLabel;

  @override
  State<GiftCardForm> createState() => _GiftCardFormState();
}

class _GiftCardFormState extends State<GiftCardForm> {
  static const Color _gold = Color(0xFFC9A227);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _validityController;
  late final TextEditingController _sortOrderController;

  String? _imageFilePath;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final GiftCardFormData? initialData = widget.initialData;

    _nameController = TextEditingController(text: initialData?.name ?? '');
    _descriptionController = TextEditingController(
      text: initialData?.description ?? '',
    );
    _amountController = TextEditingController(
      text: initialData == null ? '' : initialData.amount.toString(),
    );
    _validityController = TextEditingController(
      text: initialData == null ? '30' : initialData.validityDays.toString(),
    );
    _sortOrderController = TextEditingController(
      text: initialData == null ? '0' : initialData.sortOrder.toString(),
    );

    _imageFilePath = initialData?.imageFilePath;
    _isActive = initialData?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _validityController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _imageFilePath = image.path;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final GiftCardFormData data = GiftCardFormData(
      name: _nameController.text.trim(),
      description: _nullableText(_descriptionController.text),
      amount: int.parse(_amountController.text.trim()),
      validityDays: int.parse(_validityController.text.trim()),
      isActive: _isActive,
      sortOrder: int.parse(_sortOrderController.text.trim()),
      imageFilePath: _nullableText(_imageFilePath),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(data);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _nullableText(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  String? _requiredTextValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب.';
    }

    return null;
  }

  String? _positiveNumberValidator(String? value) {
    final int? number = int.tryParse(value?.trim() ?? '');

    if (number == null || number <= 0) {
      return 'أدخلي رقمًا أكبر من صفر.';
    }

    return null;
  }

  String? _nonNegativeNumberValidator(String? value) {
    final int? number = int.tryParse(value?.trim() ?? '');

    if (number == null || number < 0) {
      return 'أدخلي صفرًا أو رقمًا أكبر.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final _GiftCardFormColors colors = _GiftCardFormColors.from(
      widget.isDarkMode,
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: <Widget>[
          _buildImagePicker(colors),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey<String>('gift-card-name'),
            controller: _nameController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: colors.primaryText),
            validator: _requiredTextValidator,
            decoration: _decoration(
              label: 'اسم بطاقة الهدية',
              hint: 'مثال: بطاقة كراند ليان الذهبية',
              icon: Icons.card_giftcard_rounded,
              colors: colors,
            ),
          ),
          const SizedBox(height: 13),
          TextFormField(
            key: const ValueKey<String>('gift-card-description'),
            controller: _descriptionController,
            enabled: !_isSubmitting,
            maxLines: 4,
            style: TextStyle(color: colors.primaryText),
            decoration: _decoration(
              label: 'الوصف (اختياري)',
              hint: 'اكتبي وصفًا مختصرًا للبطاقة',
              icon: Icons.notes_rounded,
              colors: colors,
            ),
          ),
          const SizedBox(height: 13),
          TextFormField(
            key: const ValueKey<String>('gift-card-amount'),
            controller: _amountController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: colors.primaryText),
            validator: _positiveNumberValidator,
            decoration: _decoration(
              label: 'قيمة البطاقة بالدينار العراقي',
              hint: 'مثال: 100000',
              icon: Icons.payments_outlined,
              colors: colors,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: const ValueKey<String>('gift-card-validity'),
                  controller: _validityController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colors.primaryText),
                  validator: _positiveNumberValidator,
                  decoration: _decoration(
                    label: 'مدة الصلاحية',
                    hint: '30 يوم',
                    icon: Icons.event_available_outlined,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: const ValueKey<String>('gift-card-sort-order'),
                  controller: _sortOrderController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: colors.primaryText),
                  validator: _nonNegativeNumberValidator,
                  decoration: _decoration(
                    label: 'ترتيب الظهور',
                    hint: '0',
                    icon: Icons.swap_vert_rounded,
                    colors: colors,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: SwitchListTile.adaptive(
              key: const ValueKey<String>('gift-card-active'),
              value: _isActive,
              activeTrackColor: _gold,
              title: Text(
                'البطاقة مفعّلة',
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'تظهر للزبائن وتكون متاحة للشراء.',
                style: TextStyle(color: colors.secondaryText, fontSize: 11.5),
              ),
              onChanged: _isSubmitting
                  ? null
                  : (bool value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: FilledButton(
              key: const ValueKey<String>('gift-card-submit'),
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: widget.isDarkMode
                    ? const Color(0xFFD3B06B)
                    : const Color(0xFF171717),
                foregroundColor: widget.isDarkMode
                    ? Colors.black
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(
                      widget.submitLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(_GiftCardFormColors colors) {
    final String? imagePath = _imageFilePath;
    final bool hasLocalImage =
        imagePath != null && File(imagePath).existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting ? null : _pickImage,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 205,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (hasLocalImage)
                  Image.file(File(imagePath), fit: BoxFit.cover)
                else
                  ColoredBox(
                    color: colors.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.image_outlined,
                          color: _gold,
                          size: 42,
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'صورة بطاقة الهدية',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'الصورة اختيارية',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'اختيار صورة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    required _GiftCardFormColors colors,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: colors.secondaryText),
      hintStyle: TextStyle(color: colors.secondaryText),
      prefixIcon: Icon(icon, color: _gold),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold, width: 1.5),
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

class _GiftCardFormColors {
  const _GiftCardFormColors({
    required this.surface,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color surface;
  final Color border;
  final Color primaryText;
  final Color secondaryText;

  factory _GiftCardFormColors.from(bool isDarkMode) {
    return _GiftCardFormColors(
      surface: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      border: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
      primaryText: isDarkMode
          ? const Color(0xFFEAEAEA)
          : const Color(0xFF1C1C1C),
      secondaryText: isDarkMode
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF6B7280),
    );
  }
}
