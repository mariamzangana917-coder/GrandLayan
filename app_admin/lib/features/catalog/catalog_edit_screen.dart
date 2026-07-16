import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import 'data/catalog_models.dart';
import 'data/catalog_service.dart';

class CatalogEditScreen extends StatefulWidget {
  const CatalogEditScreen({
    required this.item,
    required this.isDarkMode,
    super.key,
  });

  final CatalogItem item;
  final bool isDarkMode;

  @override
  State<CatalogEditScreen> createState() =>
      _CatalogEditScreenState();
}

class _CatalogEditScreenState
    extends State<CatalogEditScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final CatalogService _service = const CatalogService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late final TextEditingController _instructions;

  late String _priceType;
  late bool _active;
  late int _categoryId;

  List<CatalogCategory> _categories = [];
  List<CatalogImage> _images = [];
  final List<XFile> _newImages = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _name = TextEditingController(text: item.name);
    _price = TextEditingController(
      text: item.price?.toString() ?? '',
    );
    _duration = TextEditingController(
      text: item.durationMinutes?.toString() ?? '',
    );
    _description = TextEditingController(
      text: item.description ?? '',
    );
    _instructions = TextEditingController(
      text: item.instructions ?? '',
    );

    _priceType = item.priceType;
    _active = item.isActive;
    _categoryId = item.categoryId;
    _images = [...item.images];

    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await _service.fetchCategories(
        widget.item.departmentCode,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loading = false;
      });
    } on CatalogException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 88,
    );

    if (!mounted || picked.isEmpty) return;

    setState(() {
      _newImages.addAll(picked.take(10 - _newImages.length));
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      await _service.updateItem(
        id: widget.item.id,
        categoryId: _categoryId,
        name: _name.text,
        type: widget.item.type,
        priceType: _priceType,
        price: _priceType == 'fixed'
            ? double.tryParse(_price.text.trim())
            : null,
        durationMinutes: _duration.text.trim().isEmpty
            ? null
            : int.tryParse(_duration.text.trim()),
        description: _description.text,
        instructions: _instructions.text,
        isActive: _active,
      );

      if (_newImages.isNotEmpty) {
        await _service.uploadImages(
          widget.item.id,
          _newImages.map((item) => item.path).toList(),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on CatalogException catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _show(error.message);
    }
  }

  Future<void> _deleteImage(CatalogImage image) async {
    try {
      await _service.deleteImage(
        widget.item.id,
        image.id,
      );

      if (!mounted) return;

      setState(() {
        _images.removeWhere((item) => item.id == image.id);
      });
    } on CatalogException catch (error) {
      _show(error.message);
    }
  }

  Future<void> _setMain(CatalogImage image) async {
    try {
      await _service.setMainImage(
        widget.item.id,
        image.id,
      );

      if (!mounted) return;

      setState(() {
        _images = _images
            .map(
              (item) => CatalogImage(
                id: item.id,
                url: item.url,
                isMain: item.id == image.id,
                sortOrder: item.sortOrder,
              ),
            )
            .toList();
      });
    } on CatalogException catch (error) {
      _show(error.message);
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف العنصر'),
          content: const Text(
            'هل أنتِ متأكدة؟ لا يمكن التراجع عن الحذف.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
    });

    try {
      await _service.deleteItem(widget.item.id);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on CatalogException catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _show(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final primary = dark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final secondary = dark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;
    final border = dark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'تعديل الخدمة',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              )
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: primary),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        110,
                      ),
                      children: [
                        _title('المعلومات الأساسية', primary),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _name,
                          decoration: _decoration(
                            'الاسم',
                            surface,
                            border,
                          ),
                          validator: (value) =>
                              value == null ||
                                      value.trim().isEmpty
                                  ? 'الاسم مطلوب.'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _categoryId,
                          decoration: _decoration(
                            'التصنيف',
                            surface,
                            border,
                          ),
                          items: _categories
                              .map(
                                (category) =>
                                    DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _categoryId = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _title('السعر والمدة', primary),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'fixed',
                              label: Text('سعر ثابت'),
                            ),
                            ButtonSegment(
                              value: 'inspection',
                              label: Text('بعد المعاينة'),
                            ),
                          ],
                          selected: {_priceType},
                          onSelectionChanged: (values) {
                            setState(() {
                              _priceType = values.first;
                            });
                          },
                        ),
                        if (_priceType == 'fixed') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _price,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _decoration(
                              'السعر',
                              surface,
                              border,
                            ),
                            validator: (value) {
                              if (_priceType == 'fixed' &&
                                  double.tryParse(
                                        value?.trim() ?? '',
                                      ) ==
                                      null) {
                                return 'أدخلي سعرًا صحيحًا.';
                              }

                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _duration,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(
                            'المدة بالدقائق',
                            surface,
                            border,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _title('التفاصيل', primary),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _description,
                          minLines: 3,
                          maxLines: 5,
                          decoration: _decoration(
                            'الوصف',
                            surface,
                            border,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _instructions,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _decoration(
                            'تعليمات قبل الخدمة',
                            surface,
                            border,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _title('الصور', primary),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                          ),
                          label: const Text('إضافة صور'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(
                              color: AppColors.gold,
                            ),
                            minimumSize:
                                const Size.fromHeight(46),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_images.isNotEmpty)
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final image = _images[index];

                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(13),
                                      child: Image.network(
                                        image.url,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 3,
                                      top: 3,
                                      child: IconButton.filled(
                                        onPressed: () =>
                                            _deleteImage(image),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 15,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              AppColors.error,
                                          foregroundColor:
                                              AppColors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 3,
                                      bottom: 3,
                                      child: IconButton.filled(
                                        onPressed: () =>
                                            _setMain(image),
                                        icon: Icon(
                                          image.isMain
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 17,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              AppColors.gold,
                                          foregroundColor:
                                              AppColors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        if (_newImages.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _newImages.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final image = _newImages[index];

                                return ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(13),
                                  child: Image.file(
                                    File(image.path),
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        SwitchListTile.adaptive(
                          value: _active,
                          onChanged: (value) {
                            setState(() {
                              _active = value;
                            });
                          },
                          activeColor: AppColors.gold,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'العنصر نشط',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            _active
                                ? 'يظهر للزبائن.'
                                : 'مخفي عن الزبائن.',
                            style: TextStyle(color: secondary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed:
                              _saving ? null : _deleteItem,
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          label: const Text('حذف العنصر'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(
                              color: AppColors.error,
                            ),
                            minimumSize:
                                const Size.fromHeight(46),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12,
          ),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                    ),
                  )
                : const Text(
                    'حفظ التعديلات',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    Color surface,
    Color border,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.4,
        ),
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
