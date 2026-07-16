import 'dart:io';
import 'categories/category_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'data/catalog_form_models.dart';
import 'data/catalog_form_service.dart';

enum CatalogItemKind { service, package }

enum CatalogPriceKind { fixed, inspection }

class CatalogCreateScreen extends StatefulWidget {
  const CatalogCreateScreen({
    required this.isDarkMode,
    required this.initialDepartmentCode,
    super.key,
  });

  final bool isDarkMode;
  final String initialDepartmentCode;

  @override
  State<CatalogCreateScreen> createState() => _CatalogCreateScreenState();
}

class _CatalogCreateScreenState extends State<CatalogCreateScreen> {
  static const Color _gold = Color(0xFFB89552);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final CatalogFormService _service = const CatalogFormService();

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _durationController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _instructionsController = TextEditingController();

  late String _departmentCode;

  CatalogItemKind _itemKind = CatalogItemKind.service;

  CatalogPriceKind _priceKind = CatalogPriceKind.fixed;

  List<CatalogCategoryOption> _categories = [];
  CatalogCategoryOption? _selectedCategory;

  final List<XFile> _images = [];
  final List<PackageServiceDraft> _packageServices = [];

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  bool _isActive = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _departmentCode = widget.initialDepartmentCode == 'clinic'
        ? 'clinic'
        : 'salon';

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _loadError = null;
      _selectedCategory = null;
    });

    try {
      final categories = await _service.fetchCategories(_departmentCode);

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedCategory = categories.isEmpty ? null : categories.first;
        _isLoadingCategories = false;
      });
    } on CatalogFormException catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.message;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 88);

    if (!mounted || picked.isEmpty) return;

    setState(() {
      final remaining = 10 - _images.length;
      _images.addAll(picked.take(remaining));
    });
  }

  Future<void> _selectPackageServices() async {
    try {
      final available = await _service.fetchServices(_departmentCode);

      if (!mounted) return;

      final selectedIds = _packageServices
          .map((item) => item.service.id)
          .toSet();

      final remaining = available
          .where((service) => !selectedIds.contains(service.id))
          .toList();

      if (remaining.isEmpty) {
        _showMessage('لا توجد خدمات أخرى متاحة لهذا القسم.');
        return;
      }

      final selected = await showModalBottomSheet<CatalogServiceOption>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                itemCount: remaining.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final service = remaining[index];

                  return ListTile(
                    onTap: () {
                      Navigator.of(context).pop(service);
                    },
                    leading: const Icon(Icons.spa_outlined, color: _gold),
                    title: Text(service.name, textAlign: TextAlign.right),
                    subtitle: service.durationMinutes == null
                        ? null
                        : Text(
                            '${service.durationMinutes} دقيقة',
                            textAlign: TextAlign.right,
                          ),
                    trailing: const Icon(Icons.add_rounded),
                  );
                },
              ),
            ),
          );
        },
      );

      if (selected == null || !mounted) return;

      setState(() {
        _packageServices.add(
          PackageServiceDraft(service: selected, quantity: 1),
        );
      });
    } on CatalogFormException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _openCategoryManagement() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CategoryManagementScreen(
          isDarkMode: widget.isDarkMode,
          initialDepartmentCode: _departmentCode,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadCategories();
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_selectedCategory == null) {
      _showMessage('اختاري التصنيف أولًا.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_itemKind == CatalogItemKind.package && _packageServices.isEmpty) {
      _showMessage('أضيفي خدمة واحدة على الأقل داخل البكج.');
      return;
    }

    final price = _priceKind == CatalogPriceKind.fixed
        ? double.tryParse(_priceController.text.trim())
        : null;

    final duration = _durationController.text.trim().isEmpty
        ? null
        : int.tryParse(_durationController.text.trim());

    setState(() {
      _isSaving = true;
    });

    try {
      final itemId = await _service.createCatalogItem(
        categoryId: _selectedCategory!.id,
        type: _itemKind == CatalogItemKind.service ? 'service' : 'package',
        name: _nameController.text,
        description: _descriptionController.text,
        instructions: _instructionsController.text,
        priceType: _priceKind == CatalogPriceKind.fixed
            ? 'fixed'
            : 'inspection',
        price: price,
        durationMinutes: duration,
        isActive: _isActive,
      );

      if (_images.isNotEmpty) {
        await _service.uploadImages(
          catalogItemId: itemId,
          imagePaths: _images.map((image) => image.path).toList(),
        );
      }

      if (_itemKind == CatalogItemKind.package) {
        await _service.addPackageServices(
          packageId: itemId,
          services: _packageServices,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on CatalogFormException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);

      setState(() {
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;

      _showMessage('حدث خطأ غير متوقع أثناء الحفظ.');

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark ? Colors.black : Colors.white;
    final card = dark ? const Color(0xFF111111) : const Color(0xFFF9F9F9);
    final primary = dark ? Colors.white : const Color(0xFF171717);
    final secondary = dark ? const Color(0xFFC2C2C2) : const Color(0xFF666666);
    final border = dark ? const Color(0xFF3D3D3D) : const Color(0xFFD7D7D7);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _itemKind == CatalogItemKind.service ? 'إضافة خدمة' : 'إضافة بكج',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : _loadError != null
            ? _buildLoadError(primary)
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  children: [
                    _sectionTitle('المعلومات الأساسية', primary),
                    const SizedBox(height: 10),
                    _segmentedType(),
                    const SizedBox(height: 12),
                    _departmentSelector(card, border, primary),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<CatalogCategoryOption>(
                            value: _selectedCategory,
                            decoration: _decoration('التصنيف', border),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'اختاري التصنيف.' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _openCategoryManagement,
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('إدارة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _gold,
                              side: const BorderSide(color: _gold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: _decoration(
                        _itemKind == CatalogItemKind.service
                            ? 'اسم الخدمة'
                            : 'اسم البكج',
                        border,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اكتبي الاسم.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle('السعر والمدة', primary),
                    const SizedBox(height: 10),
                    _priceTypeSelector(),
                    if (_priceKind == CatalogPriceKind.fixed) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'السعر بالدينار العراقي',
                          border,
                        ),
                        validator: (value) {
                          if (_priceKind == CatalogPriceKind.fixed &&
                              (value == null ||
                                  double.tryParse(value.trim()) == null ||
                                  double.parse(value.trim()) < 0)) {
                            return 'أدخلي سعرًا صحيحًا.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration('المدة بالدقائق', border),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }

                        final parsed = int.tryParse(value.trim());

                        if (parsed == null || parsed <= 0) {
                          return 'المدة يجب أن تكون أكبر من صفر.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle('التفاصيل', primary),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _decoration('الوصف', border),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instructionsController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _decoration('تعليمات قبل الخدمة', border),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle('الصور', primary),
                    const SizedBox(height: 10),
                    _imagesSection(card, border, primary, secondary),
                    if (_itemKind == CatalogItemKind.package) ...[
                      const SizedBox(height: 22),
                      _sectionTitle('محتويات البكج', primary),
                      const SizedBox(height: 10),
                      _packageServicesSection(card, border, primary, secondary),
                    ],
                    const SizedBox(height: 18),
                    SwitchListTile.adaptive(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: _gold,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'إظهار العنصر للزبائن',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'العنصر نشط ومتاح.'
                            : 'العنصر مخفي وغير متاح.',
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: dark
                    ? const Color(0xFFD3B06B)
                    : const Color(0xFF171717),
                foregroundColor: dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text(
                      'حفظ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentedType() {
    return SegmentedButton<CatalogItemKind>(
      segments: const [
        ButtonSegment(
          value: CatalogItemKind.service,
          label: Text('خدمة'),
          icon: Icon(Icons.spa_outlined),
        ),
        ButtonSegment(
          value: CatalogItemKind.package,
          label: Text('بكج'),
          icon: Icon(Icons.inventory_2_outlined),
        ),
      ],
      selected: {_itemKind},
      onSelectionChanged: (selection) {
        setState(() {
          _itemKind = selection.first;
        });
      },
    );
  }

  Widget _priceTypeSelector() {
    return SegmentedButton<CatalogPriceKind>(
      segments: const [
        ButtonSegment(value: CatalogPriceKind.fixed, label: Text('سعر ثابت')),
        ButtonSegment(
          value: CatalogPriceKind.inspection,
          label: Text('بعد المعاينة'),
        ),
      ],
      selected: {_priceKind},
      onSelectionChanged: (selection) {
        setState(() {
          _priceKind = selection.first;
        });
      },
    );
  }

  Widget _departmentSelector(Color card, Color border, Color primary) {
    return DropdownButtonFormField<String>(
      value: _departmentCode,
      decoration: _decoration('القسم', border),
      items: const [
        DropdownMenuItem(value: 'salon', child: Text('الصالون')),
        DropdownMenuItem(value: 'clinic', child: Text('العيادة')),
      ],
      onChanged: (value) {
        if (value == null || value == _departmentCode) {
          return;
        }

        setState(() {
          _departmentCode = value;
          _packageServices.clear();
        });

        _loadCategories();
      },
    );
  }

  Widget _imagesSection(
    Color card,
    Color border,
    Color primary,
    Color secondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _images.length >= 10 ? null : _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            _images.isEmpty
                ? 'اختيار صور'
                : 'إضافة صور أخرى (${_images.length}/10)',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            side: const BorderSide(color: _gold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = _images[index];

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(image.path),
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 88,
                            height: 88,
                            color: card,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              color: _gold,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 2,
                      left: 2,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _images.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Text(
            'أول صورة ستكون الصورة الرئيسية.',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
        ],
      ],
    );
  }

  Widget _packageServicesSection(
    Color card,
    Color border,
    Color primary,
    Color secondary,
  ) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _selectPackageServices,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة خدمة إلى البكج'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            side: const BorderSide(color: _gold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_packageServices.isEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'لم تتم إضافة خدمات بعد.',
              style: TextStyle(color: secondary, fontSize: 12),
            ),
          )
        else
          ..._packageServices.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.service.name,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: item.quantity <= 1
                        ? null
                        : () {
                            setState(() {
                              _packageServices[index] = item.copyWith(
                                quantity: item.quantity - 1,
                              );
                            });
                          },
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    item.quantity.toString(),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _packageServices[index] = item.copyWith(
                          quantity: item.quantity + 1,
                        );
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _packageServices.removeAt(index);
                      });
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLoadError(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: primary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, Color border) {
    return InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _gold, width: 1.4),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
