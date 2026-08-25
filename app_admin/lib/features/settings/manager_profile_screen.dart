import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import 'data/manager_profile_model.dart';
import 'data/manager_profile_service.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  static const Color _gold = Color(0xFFB89552);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ManagerProfileService _service = ManagerProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  ManagerProfile? _profile;
  File? _selectedImage;
  String? _loadError;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _deleteAvatarRequested = false;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final ManagerProfile profile = await _service.fetchProfile();

      if (!mounted) {
        return;
      }

      _applyProfile(profile);

      setState(() {
        _profile = profile;
        _selectedImage = null;
        _deleteAvatarRequested = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = _messageFor(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isSaving) {
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (!mounted || image == null) {
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
        _deleteAvatarRequested = false;
      });
    } catch (_) {
      _showMessage('تعذر فتح معرض الصور.');
    }
  }

  Future<void> _requestDeleteAvatar() async {
    final bool hasAvatar =
        _selectedImage != null ||
        (!_deleteAvatarRequested && (_profile?.avatar?.isNotEmpty ?? false));

    if (!hasAvatar || _isSaving) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final _ProfilePalette palette = _ProfilePalette.fromDarkMode(
          widget.isDarkMode,
        );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: palette.card,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'حذف صورة الحساب؟',
              style: TextStyle(
                color: palette.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'سترجع صورة الحساب إلى الأحرف الافتراضية بعد الحفظ.',
              style: TextStyle(color: palette.secondaryText, height: 1.5),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD84A4A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف الصورة'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true && mounted) {
      setState(() {
        _selectedImage = null;
        _deleteAvatarRequested = true;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _showValidation = true;
    });

    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      ManagerProfile updated = await _service.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
      );

      if (_selectedImage != null) {
        try {
          updated = await _service.updateAvatar(image: _selectedImage!);
        } catch (error) {
          if (!mounted) {
            return;
          }

          _applyProfile(updated);
          setState(() {
            _profile = updated;
            _isSaving = false;
          });

          _showMessage(
            'تم تحديث البيانات، لكن تعذر تحديث الصورة: ${_messageFor(error)}',
          );
          return;
        }
      } else if (_deleteAvatarRequested) {
        try {
          updated = await _service.deleteAvatar();
        } catch (error) {
          if (!mounted) {
            return;
          }

          _applyProfile(updated);
          setState(() {
            _profile = updated;
            _isSaving = false;
          });

          _showMessage(
            'تم تحديث البيانات، لكن تعذر حذف الصورة: ${_messageFor(error)}',
          );
          return;
        }
      }

      if (!mounted) {
        return;
      }

      _applyProfile(updated);

      setState(() {
        _profile = updated;
        _selectedImage = null;
        _deleteAvatarRequested = false;
        _isSaving = false;
      });

      _showMessage('تم حفظ بيانات حساب المديرة بنجاح.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(_messageFor(error));
    }
  }

  void _applyProfile(ManagerProfile profile) {
    _nameController.text = profile.name;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return error.message.toString();
    }

    if (error is FormatException) {
      return error.message.toString();
    }

    return 'حدث خطأ أثناء الاتصال بالخادم. حاولي مجددًا.';
  }

  @override
  Widget build(BuildContext context) {
    final _ProfilePalette palette = _ProfilePalette.fromDarkMode(
      widget.isDarkMode,
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: <Widget>[
              _buildHeader(palette),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _gold),
                      )
                    : _loadError != null
                    ? _buildErrorState(palette)
                    : _buildContent(palette),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isLoading || _loadError != null
          ? null
          : _buildSaveBar(palette),
    );
  }

  Widget _buildHeader(_ProfilePalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 16, 6),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).maybePop(_profile),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
            tooltip: 'رجوع',
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: palette.primaryText,
              size: 19,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'بيانات حساب المديرة',
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_ProfilePalette palette) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalPadding = constraints.maxWidth >= 600 ? 28 : 16;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                132,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: _showValidation
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildProfileCard(palette),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      title: 'المعلومات الأساسية',
                      palette: palette,
                    ),
                    const SizedBox(height: 10),
                    _buildFormCard(palette),
                    const SizedBox(height: 18),
                    _buildSecurityNote(palette),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(_ProfilePalette palette) {
    final String displayName = _nameController.text.trim().isEmpty
        ? 'مديرة Grand Layan'
        : _nameController.text.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: widget.isDarkMode
              ? const <Color>[Color(0xFF2A2419), Color(0xFF171717)]
              : const <Color>[Color(0xFFFFFBF3), Color(0xFFF4E5C9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? const Color(0xFF4A3B25)
              : const Color(0xFFE8D3AC),
          width: 0.9,
        ),
      ),
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _buildAvatar(palette),
              Positioned(
                left: -3,
                bottom: -3,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.card, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder:
                (BuildContext context, TextEditingValue value, Widget? child) {
                  final String name = value.text.trim().isEmpty
                      ? displayName
                      : value.text.trim();

                  return Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
          ),
          const SizedBox(height: 5),
          Text(
            'حساب الإدارة الرئيسي',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(
                  _selectedImage != null ||
                          (!_deleteAvatarRequested &&
                              (_profile?.avatar?.isNotEmpty ?? false))
                      ? 'تغيير الصورة'
                      : 'إضافة صورة',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: BorderSide(color: _gold.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_selectedImage != null ||
                  (!_deleteAvatarRequested &&
                      (_profile?.avatar?.isNotEmpty ?? false)))
                TextButton.icon(
                  onPressed: _requestDeleteAvatar,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD84A4A),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_ProfilePalette palette) {
    final String initials = _initialsFor(_nameController.text);

    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    final String? avatar = _deleteAvatarRequested ? null : _profile?.avatar;

    if (avatar != null && avatar.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return _buildInitialsAvatar(initials, palette);
              },
          loadingBuilder:
              (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return _buildInitialsAvatar(initials, palette);
              },
        ),
      );
    }

    return _buildInitialsAvatar(initials, palette);
  }

  Widget _buildInitialsAvatar(String initials, _ProfilePalette palette) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: widget.isDarkMode ? 0.2 : 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: _gold,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFormCard(_ProfilePalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border, width: 0.8),
      ),
      child: Column(
        children: <Widget>[
          _ProfileTextField(
            controller: _nameController,
            label: 'اسم المديرة',
            hint: 'اكتبي الاسم الكامل',
            icon: Icons.person_outline_rounded,
            palette: palette,
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              final String name = value?.trim() ?? '';
              if (name.isEmpty) {
                return 'اسم المديرة مطلوب.';
              }
              if (name.length < 2) {
                return 'اسم المديرة قصير جدًا.';
              }
              if (name.length > 120) {
                return 'اسم المديرة طويل جدًا.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _ProfileTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: 'مثال: 07701234567',
            icon: Icons.phone_outlined,
            palette: palette,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              final String phone = (value ?? '')
                  .replaceAll(RegExp(r'[\s\-()]'), '')
                  .trim();

              if (phone.isEmpty) {
                return 'رقم الهاتف مطلوب.';
              }
              if (!RegExp(r'^\+?[0-9]{7,20}$').hasMatch(phone)) {
                return 'رقم الهاتف غير صحيح.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _ProfileTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'name@example.com',
            icon: Icons.alternate_email_rounded,
            palette: palette,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            validator: (String? value) {
              final String email = value?.trim() ?? '';
              if (email.isEmpty) {
                return 'البريد الإلكتروني مطلوب.';
              }
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                return 'البريد الإلكتروني غير صحيح.';
              }
              if (email.length > 255) {
                return 'البريد الإلكتروني طويل جدًا.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _ReadOnlyInfoTile(
            icon: Icons.admin_panel_settings_outlined,
            label: 'نوع الحساب',
            value: 'مديرة النظام',
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(_ProfilePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: widget.isDarkMode ? 0.11 : 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.verified_user_outlined, color: _gold, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'تغيير البريد أو رقم الهاتف لا يسجّل خروج الأجهزة الأخرى. كلمة المرور تُغيّر من الصفحة المخصصة لها فقط.',
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(_ProfilePalette palette) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.isDarkMode
                        ? const Color(0xFFD3B06B)
                        : const Color(0xFF1C1C1C),
                    foregroundColor: widget.isDarkMode
                        ? const Color(0xFF121212)
                        : Colors.white,
                    disabledBackgroundColor: palette.border,
                    disabledForegroundColor: palette.secondaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSaving
                      ? SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: widget.isDarkMode
                                ? const Color(0xFF121212)
                                : Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(_ProfilePalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: _gold,
                  size: 31,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _loadError ?? 'تعذر تحميل بيانات الحساب.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialsFor(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'GL';
    }

    String firstCharacters(String text, int count) {
      return String.fromCharCodes(text.runes.take(count));
    }

    if (parts.length == 1) {
      return firstCharacters(parts.first, 2).toUpperCase();
    }

    return '${firstCharacters(parts.first, 1)}'
            '${firstCharacters(parts.last, 1)}'
        .toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.palette});

  final String title;
  final _ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _ManagerProfileScreenState._gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.palette,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final _ProfilePalette palette;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _ManagerProfileScreenState._gold,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 21),
        filled: true,
        fillColor: palette.field,
        labelStyle: TextStyle(color: palette.secondaryText),
        hintStyle: TextStyle(
          color: palette.secondaryText.withValues(alpha: 0.7),
          fontSize: 12.5,
        ),
        prefixIconColor: _ManagerProfileScreenState._gold,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _ManagerProfileScreenState._gold,
            width: 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD84A4A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD84A4A), width: 1.3),
        ),
      ),
    );
  }
}

class _ReadOnlyInfoTile extends StatelessWidget {
  const _ReadOnlyInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final _ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: _ManagerProfileScreenState._gold, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            color: palette.secondaryText.withValues(alpha: 0.7),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfilePalette {
  const _ProfilePalette({
    required this.background,
    required this.card,
    required this.field,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
  });

  factory _ProfilePalette.fromDarkMode(bool isDark) {
    if (isDark) {
      return const _ProfilePalette(
        background: Color(0xFF121212),
        card: Color(0xFF1E1E1E),
        field: Color(0xFF232323),
        primaryText: Color(0xFFEAEAEA),
        secondaryText: Color(0xFF9CA3AF),
        border: Color(0xFF2A2A2A),
      );
    }

    return const _ProfilePalette(
      background: Color(0xFFF5F5F5),
      card: Color(0xFFFFFFFF),
      field: Color(0xFFF8F8F8),
      primaryText: Color(0xFF1C1C1C),
      secondaryText: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    );
  }

  final Color background;
  final Color card;
  final Color field;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
}
