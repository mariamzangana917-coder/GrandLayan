import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_offer.dart';
import '../data/offer_repository.dart';

class OfferFormScreen extends StatefulWidget {
  const OfferFormScreen({
    required this.isDarkMode,
    required this.repository,
    this.offer,
    super.key,
  });

  final bool isDarkMode;
  final OfferRepository repository;
  final AdminOffer? offer;

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _badgeController;
  late final TextEditingController _valueController;
  late final TextEditingController _detailsController;
  late final TextEditingController _sortOrderController;

  List<OfferDepartment> _departments = <OfferDepartment>[];
  List<OfferCatalogItem> _catalogItems = <OfferCatalogItem>[];

  int? _departmentId;
  int? _catalogItemId;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isActive = true;
  XFile? _selectedImage;

  bool _isLoadingLookups = true;
  bool _isLoadingCatalog = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.offer != null;

  @override
  void initState() {
    super.initState();

    final AdminOffer? offer = widget.offer;

    _titleController = TextEditingController(text: offer?.title ?? '');
    _descriptionController = TextEditingController(
      text: offer?.description ?? '',
    );
    _badgeController = TextEditingController(text: offer?.badgeText ?? '');
    _valueController = TextEditingController(text: offer?.valueText ?? '');
    _detailsController = TextEditingController(text: offer?.detailsText ?? '');
    _sortOrderController = TextEditingController(
      text: (offer?.sortOrder ?? 0).toString(),
    );

    _departmentId = offer?.department.id;
    _catalogItemId = offer?.catalogItem?.id;
    _startsAt =
        offer?.startsAt.toLocal() ??
        DateTime.now().subtract(const Duration(minutes: 1));
    _endsAt =
        offer?.endsAt.toLocal() ?? DateTime.now().add(const Duration(days: 7));
    _isActive = offer?.isActive ?? true;

    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _badgeController.dispose();
    _valueController.dispose();
    _detailsController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _errorMessage = null;
    });

    try {
      final List<OfferDepartment> departments = await widget.repository
          .fetchDepartments();

      if (!mounted) {
        return;
      }

      int? selectedDepartmentId = _departmentId;

      if (selectedDepartmentId == null && departments.isNotEmpty) {
        selectedDepartmentId = departments.first.id;
      }

      setState(() {
        _departments = departments;
        _departmentId = selectedDepartmentId;
        _isLoadingLookups = false;
      });

      await _loadCatalogItems(keepSelection: true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoadingLookups = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل أقسام العرض.';
        _isLoadingLookups = false;
      });
    }
  }

  Future<void> _loadCatalogItems({bool keepSelection = false}) async {
    final OfferDepartment? department = _selectedDepartment;

    if (department == null) {
      setState(() {
        _catalogItems = <OfferCatalogItem>[];
        _catalogItemId = null;
      });
      return;
    }

    setState(() {
      _isLoadingCatalog = true;

      if (!keepSelection) {
        _catalogItemId = null;
      }
    });

    try {
      final List<OfferCatalogItem> items = await widget.repository
          .fetchCatalogItems(departmentCode: department.code);

      if (!mounted) {
        return;
      }

      final bool selectedExists = items.any(
        (OfferCatalogItem item) => item.id == _catalogItemId,
      );

      setState(() {
        _catalogItems = items;

        if (!selectedExists) {
          _catalogItemId = null;
        }

        _isLoadingCatalog = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogItems = <OfferCatalogItem>[];
        _catalogItemId = null;
        _isLoadingCatalog = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogItems = <OfferCatalogItem>[];
        _catalogItemId = null;
        _isLoadingCatalog = false;
        _errorMessage = 'تعذر تحميل خدمات وبكجات القسم.';
      });
    }
  }

  OfferDepartment? get _selectedDepartment {
    for (final OfferDepartment department in _departments) {
      if (department.id == _departmentId) {
        return department;
      }
    }

    return null;
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
      _selectedImage = image;
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime initial = isStart
        ? (_startsAt ?? DateTime.now())
        : (_endsAt ?? DateTime.now().add(const Duration(days: 7)));

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: isStart ? 'تاريخ بداية العرض' : 'تاريخ نهاية العرض',
    );

    if (date == null || !mounted) {
      return;
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: isStart ? 'وقت بداية العرض' : 'وقت نهاية العرض',
    );

    if (time == null || !mounted) {
      return;
    }

    final DateTime value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startsAt = value;

        if (_endsAt == null || !_endsAt!.isAfter(value)) {
          _endsAt = value.add(const Duration(days: 7));
        }
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_departmentId == null) {
      _showMessage('اختاري قسم العرض.');
      return;
    }

    if (_startsAt == null || _endsAt == null) {
      _showMessage('حددي بداية العرض ونهايته.');
      return;
    }

    if (!_endsAt!.isAfter(_startsAt!)) {
      _showMessage('نهاية العرض يجب أن تكون بعد بدايته.');
      return;
    }

    if (!_isEditing && _selectedImage == null) {
      _showMessage('اختاري صورة العرض.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> fields = <String, dynamic>{
      'department_id': _departmentId,
      'catalog_item_id': _catalogItemId,
      'title': _titleController.text.trim(),
      'description': _nullableText(_descriptionController.text),
      'badge_text': _nullableText(_badgeController.text),
      'value_text': _nullableText(_valueController.text),
      'details_text': _nullableText(_detailsController.text),
      'starts_at': _startsAt!.toUtc().toIso8601String(),
      'ends_at': _endsAt!.toUtc().toIso8601String(),
      'is_active': _isActive,
      'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
    };

    try {
      AdminOffer savedOffer;

      if (_isEditing) {
        savedOffer = await widget.repository.updateOffer(
          offerId: widget.offer!.id,
          fields: fields,
        );

        if (_selectedImage != null) {
          savedOffer = await widget.repository.replaceImage(
            offerId: savedOffer.id,
            imagePath: _selectedImage!.path,
          );
        }
      } else {
        savedOffer = await widget.repository.createOffer(
          fields: fields,
          imagePath: _selectedImage!.path,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(savedOffer);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = _apiErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'حدث خطأ أثناء حفظ العرض.';
      });
    }
  }

  String _apiErrorMessage(ApiException error) {
    for (final List<String> errors in error.validationErrors.values) {
      if (errors.isNotEmpty) {
        return errors.first;
      }
    }

    return error.message;
  }

  String? _nullableText(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final _OfferFormColors colors = _OfferFormColors.from(widget.isDarkMode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: colors.background,
          foregroundColor: colors.primaryText,
          title: Text(
            _isEditing ? 'تعديل العرض' : 'إضافة عرض',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        body: _isLoadingLookups
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB89552)),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: <Widget>[
                    _buildImagePicker(colors),
                    const SizedBox(height: 18),
                    if (_errorMessage != null) ...<Widget>[
                      _buildError(),
                      const SizedBox(height: 14),
                    ],
                    _field(
                      controller: _titleController,
                      label: 'عنوان العرض',
                      hint: 'مثال: عرض العناية المتكاملة',
                      colors: colors,
                      validator: (String? value) {
                        final String text = value?.trim() ?? '';

                        if (text.length < 3) {
                          return 'عنوان العرض مطلوب.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _departmentId,
                      decoration: _decoration(label: 'القسم', colors: colors),
                      dropdownColor: colors.surface,
                      style: TextStyle(color: colors.primaryText),
                      items: _departments
                          .map(
                            (OfferDepartment department) =>
                                DropdownMenuItem<int>(
                                  value: department.id,
                                  child: Text(department.name),
                                ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (int? value) {
                              setState(() {
                                _departmentId = value;
                              });
                              _loadCatalogItems();
                            },
                      validator: (int? value) {
                        if (value == null) {
                          return 'اختاري القسم.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _catalogItemId,
                      isExpanded: true,
                      decoration: _decoration(
                        label: 'الخدمة أو البكج المرتبط (اختياري)',
                        colors: colors,
                        suffix: _isLoadingCatalog
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFB89552),
                                ),
                              )
                            : null,
                      ),
                      dropdownColor: colors.surface,
                      style: TextStyle(color: colors.primaryText),
                      items: _catalogItems
                          .map(
                            (OfferCatalogItem item) => DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving || _isLoadingCatalog
                          ? null
                          : (int? value) {
                              setState(() {
                                _catalogItemId = value;
                              });
                            },
                    ),
                    if (_catalogItemId != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _catalogItemId = null;
                                  });
                                },
                          icon: const Icon(Icons.link_off_rounded),
                          label: const Text('إلغاء ربط الخدمة'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _descriptionController,
                      label: 'وصف العرض',
                      hint: 'اكتبي وصفًا واضحًا ومختصرًا',
                      colors: colors,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _field(
                            controller: _badgeController,
                            label: 'الشارة',
                            hint: 'VIP',
                            colors: colors,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller: _valueController,
                            label: 'القيمة الظاهرة',
                            hint: 'خصم 20%',
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _detailsController,
                      label: 'النص المختصر',
                      hint: 'لفترة محدودة',
                      colors: colors,
                    ),
                    const SizedBox(height: 12),
                    _buildDateTile(
                      title: 'بداية العرض',
                      value: _startsAt,
                      colors: colors,
                      onTap: () => _pickDateTime(isStart: true),
                    ),
                    const SizedBox(height: 10),
                    _buildDateTile(
                      title: 'نهاية العرض',
                      value: _endsAt,
                      colors: colors,
                      onTap: () => _pickDateTime(isStart: false),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _sortOrderController,
                      label: 'ترتيب الظهور',
                      hint: '0',
                      colors: colors,
                      keyboardType: TextInputType.number,
                      validator: (String? value) {
                        final int? number = int.tryParse(value?.trim() ?? '');

                        if (number == null || number < 0) {
                          return 'الترتيب يجب أن يكون صفرًا أو أكبر.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: SwitchListTile.adaptive(
                        value: _isActive,
                        activeTrackColor: const Color(0xFFB89552),
                        title: Text(
                          'العرض مفعّل',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          'لن يظهر للزبونة إلا ضمن مدة العرض المحددة.',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: _isSaving
                            ? null
                            : (bool value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _submit,
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
                        child: _isSaving
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                ),
                              )
                            : Text(
                                _isEditing ? 'حفظ التعديلات' : 'إنشاء العرض',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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

  Widget _buildImagePicker(_OfferFormColors colors) {
    final XFile? selectedImage = _selectedImage;
    final String? existingImageUrl = widget.offer?.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : _pickImage,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 210,
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
                if (selectedImage != null)
                  Image.file(File(selectedImage.path), fit: BoxFit.cover)
                else if (existingImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: existingImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB89552),
                      ),
                    ),
                    errorWidget: (_, _, _) => _imagePlaceholder(colors),
                  )
                else
                  _imagePlaceholder(colors),
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

  Widget _imagePlaceholder(_OfferFormColors colors) {
    return ColoredBox(
      color: colors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.image_outlined, color: Color(0xFFB89552), size: 42),
          const SizedBox(height: 9),
          Text(
            'صورة العرض',
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF351414)
            : const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.isDarkMode
              ? const Color(0xFFFFA0A0)
              : const Color(0xFFB42318),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required _OfferFormColors colors,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.primaryText),
      validator: validator,
      decoration: _decoration(label: label, hint: hint, colors: colors),
    );
  }

  InputDecoration _decoration({
    required String label,
    required _OfferFormColors colors,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.all(13), child: suffix),
      labelStyle: TextStyle(color: colors.secondaryText),
      hintStyle: TextStyle(color: colors.secondaryText),
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
        borderSide: const BorderSide(color: Color(0xFFB89552), width: 1.5),
      ),
    );
  }

  Widget _buildDateTile({
    required String title,
    required DateTime? value,
    required _OfferFormColors colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.event_outlined, color: Color(0xFFB89552)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value == null ? 'غير محدد' : _formatDateTime(value),
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: colors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final int hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final String minute = local.minute.toString().padLeft(2, '0');
    final String period = local.hour >= 12 ? 'م' : 'ص';

    return '${local.day}/${local.month}/${local.year} - '
        '$hour:$minute $period';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OfferFormColors {
  const _OfferFormColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color primaryText;
  final Color secondaryText;

  factory _OfferFormColors.from(bool isDarkMode) {
    return _OfferFormColors(
      background: isDarkMode ? Colors.black : Colors.white,
      surface: isDarkMode ? const Color(0xFF111111) : const Color(0xFFF8F8F8),
      border: isDarkMode ? const Color(0xFF2B2B2B) : const Color(0xFFE8E8E8),
      primaryText: isDarkMode ? Colors.white : const Color(0xFF171717),
      secondaryText: isDarkMode
          ? const Color(0xFFB8B8B8)
          : const Color(0xFF747474),
    );
  }
}
