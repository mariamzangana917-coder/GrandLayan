import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_url.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/customer_user.dart';
import '../../../auth/providers/customer_auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({required this.customer, super.key});

  final CustomerUser customer;

  @override
  ConsumerState<EditProfilePage> createState() {
    return _EditProfilePageState();
  }
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late CustomerUser _customer;

  bool _isSaving = false;
  bool _isAvatarBusy = false;

  bool get _isBusy => _isSaving || _isAvatarBusy;

  String? get _avatarUrl {
    return ApiUrl.resolveStorageUrl(_customer.avatar);
  }

  @override
  void initState() {
    super.initState();

    _customer = widget.customer;

    _nameController = TextEditingController(text: widget.customer.name);

    _phoneController = TextEditingController(text: widget.customer.phone);

    _emailController = TextEditingController(text: widget.customer.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'يرجى إدخال الاسم.';
    }

    if (name.length < 2) {
      return 'الاسم يجب أن يتكون من حرفين على الأقل.';
    }

    if (name.length > 100) {
      return 'الاسم طويل جدًا.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(' ', '').trim() ?? '';

    if (phone.isEmpty) {
      return 'يرجى إدخال رقم الهاتف.';
    }

    final isValid = RegExp(r'^[0-9+]{8,20}$').hasMatch(phone);

    if (!isValid) {
      return 'يرجى إدخال رقم هاتف صحيح.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني.';
    }

    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!isValid) {
      return 'يرجى إدخال بريد إلكتروني صحيح.';
    }

    return null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || _isBusy) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedCustomer = await ref
          .read(customerAuthProvider.notifier)
          .updateProfile(
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _customer = updatedCustomer;
      });

      _showSuccess('تم تحديث بياناتكِ بنجاح.');

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('حدث خطأ غير متوقع أثناء تحديث البيانات.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showAvatarOptions() async {
    if (_isBusy) {
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);

    final primaryTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1C1C1C);

    final secondaryTextColor = isDark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF6B7280);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _avatarUrl == null
                        ? 'إضافة صورة للحساب'
                        : 'تعديل صورة الحساب',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اختاري صورة واضحة من معرض الصور.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _AvatarActionTile(
                    icon: Icons.photo_library_outlined,
                    title: _avatarUrl == null ? 'اختيار صورة' : 'تغيير الصورة',
                    iconColor: AppColors.gold,
                    textColor: primaryTextColor,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _pickAndUploadAvatar();
                    },
                  ),
                  if (_avatarUrl != null) ...[
                    const SizedBox(height: 10),
                    _AvatarActionTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'حذف الصورة',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _confirmDeleteAvatar();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isBusy) {
      return;
    }

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (pickedImage == null) {
        return;
      }

      final imageFile = File(pickedImage.path);

      if (!await imageFile.exists()) {
        _showError('تعذر قراءة الصورة المختارة.');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isAvatarBusy = true;
      });

      final updatedCustomer = await ref
          .read(customerAuthProvider.notifier)
          .updateAvatar(image: imageFile);

      if (!mounted) {
        return;
      }

      setState(() {
        _customer = updatedCustomer;
      });

      _showSuccess('تم تحديث صورة الحساب بنجاح.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('حدث خطأ أثناء رفع الصورة. يرجى المحاولة مجددًا.');
    } finally {
      if (mounted) {
        setState(() {
          _isAvatarBusy = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteAvatar() async {
    if (_isBusy || _avatarUrl == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        final primaryTextColor = isDark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1C1C1C);

        final secondaryTextColor = isDark
            ? const Color(0xFFB3B3B3)
            : const Color(0xFF6B7280);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'حذف صورة الحساب',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'هل أنتِ متأكدة من حذف صورة الحساب؟',
              textAlign: TextAlign.right,
              style: TextStyle(color: secondaryTextColor, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('تراجع'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف الصورة'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _deleteAvatar();
  }

  Future<void> _deleteAvatar() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isAvatarBusy = true;
    });

    try {
      final updatedCustomer = await ref
          .read(customerAuthProvider.notifier)
          .deleteAvatar();

      if (!mounted) {
        return;
      }

      setState(() {
        _customer = updatedCustomer;
      });

      _showSuccess('تم حذف صورة الحساب.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('حدث خطأ أثناء حذف الصورة. يرجى المحاولة مجددًا.');
    } finally {
      if (mounted) {
        setState(() {
          _isAvatarBusy = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);

    final primaryTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1C1C1C);

    final secondaryTextColor = isDark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF6B7280);

    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E7EB);

    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'بياناتي',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: _isBusy
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
          ),
        ),
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _ProfileAvatar(
                          avatarUrl: _avatarUrl,
                          isLoading: _isAvatarBusy,
                          onTap: _showAvatarOptions,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _customer.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _isBusy ? null : _showAvatarOptions,
                          icon: Icon(
                            _avatarUrl == null
                                ? Icons.add_a_photo_outlined
                                : Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _avatarUrl == null ? 'إضافة صورة' : 'تغيير الصورة',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          'يمكنكِ تعديل صورتكِ وبيانات حسابكِ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProfileTextField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    hint: 'أدخلي اسمكِ الكامل',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: _validateName,
                    enabled: !_isBusy,
                    surfaceColor: surfaceColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 15),
                  _ProfileTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    hint: 'أدخلي رقم الهاتف',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: _validatePhone,
                    enabled: !_isBusy,
                    surfaceColor: surfaceColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 15),
                  _ProfileTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    hint: 'أدخلي البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: _validateEmail,
                    enabled: !_isBusy,
                    surfaceColor: surfaceColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    onSubmitted: (_) {
                      _saveProfile();
                    },
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _isBusy ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF1C1C1C),
                        disabledBackgroundColor: AppColors.gold.withValues(
                          alpha: 0.55,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Color(0xFF1C1C1C),
                              ),
                            )
                          : const Text('حفظ التعديلات'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.isLoading,
    required this.onTap,
    required this.isDark,
  });

  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: avatarUrl == null ? 'إضافة صورة للحساب' : 'تغيير صورة الحساب',
      child: InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.12),
                border: Border.all(color: AppColors.gold, width: 1.4),
              ),
              child: ClipOval(
                child: avatarUrl == null
                    ? Container(
                        color: AppColors.gold.withValues(
                          alpha: isDark ? 0.13 : 0.08,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: AppColors.gold,
                        ),
                      )
                    : Image.network(
                        avatarUrl!,
                        width: 98,
                        height: 98,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.gold.withValues(
                              alpha: isDark ? 0.13 : 0.08,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppColors.gold,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.gold,
                            ),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              left: -2,
              bottom: 2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Color(0xFF1C1C1C),
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.48),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarActionTile extends StatelessWidget {
  const _AvatarActionTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: textColor.withValues(alpha: 0.65),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.textInputAction,
    required this.validator,
    required this.enabled,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final bool enabled;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: primaryTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.gold, size: 21),
        filled: true,
        fillColor: surfaceColor,
        labelStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
        hintStyle: TextStyle(
          color: secondaryTextColor.withValues(alpha: 0.75),
          fontSize: 13,
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: borderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}
