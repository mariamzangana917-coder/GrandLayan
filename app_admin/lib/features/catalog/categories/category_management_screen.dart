import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'admin_category_model.dart';
import 'admin_category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({
    required this.isDarkMode,
    required this.initialDepartmentCode,
    super.key,
  });

  final bool isDarkMode;
  final String initialDepartmentCode;

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  static const _gold = Color(0xFFB89552);
  final _service = const AdminCategoryService();

  late String _departmentCode;
  List<AdminCategory> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _departmentCode = widget.initialDepartmentCode == 'clinic'
        ? 'clinic'
        : 'salon';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _service.fetchCategories(_departmentCode);
      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loading = false;
      });
    } on AdminCategoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  int? get _departmentId {
    for (final item in _categories) {
      if (item.departmentId > 0) return item.departmentId;
    }
    return _departmentCode == 'salon' ? 1 : 2;
  }

  Future<void> _edit([AdminCategory? category]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CategoryEditor(
        isDarkMode: widget.isDarkMode,
        departmentId: category?.departmentId ?? _departmentId!,
        category: category,
      ),
    );

    if (changed == true && mounted) {
      await _load();
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
        centerTitle: true,
        title: const Text(
          'إدارة التصنيفات',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          color: _gold,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Row(
                children: [
                  PopupMenuButton<String>(
                    initialValue: _departmentCode,
                    position: PopupMenuPosition.under,
                    onSelected: (value) {
                      if (value == _departmentCode) return;
                      setState(() => _departmentCode = value);
                      _load();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'salon', child: Text('الصالون')),
                      PopupMenuItem(value: 'clinic', child: Text('العيادة')),
                    ],
                    child: Row(
                      children: [
                        Icon(
                          _departmentCode == 'salon'
                              ? Icons.spa_outlined
                              : Icons.medical_services_outlined,
                          color: _gold,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _departmentCode == 'salon' ? 'الصالون' : 'العيادة',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: secondary,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _loading ? null : () => _edit(),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('إدارة التصنيفات'),
                    style: FilledButton.styleFrom(
                      backgroundColor: dark
                          ? const Color(0xFFD3B06B)
                          : const Color(0xFF171717),
                      foregroundColor: dark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(child: CircularProgressIndicator(color: _gold)),
                )
              else if (_error != null)
                _messageState(
                  icon: Icons.cloud_off_outlined,
                  title: _error!,
                  primary: primary,
                  onPressed: _load,
                )
              else if (_categories.isEmpty)
                _messageState(
                  icon: Icons.category_outlined,
                  title: 'لا توجد تصنيفات',
                  primary: primary,
                )
              else
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _edit(category),
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              _CategoryImage(url: category.imageUrl, size: 66),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: primary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          category.isActive ? 'نشط' : 'غير نشط',
                                          style: TextStyle(
                                            color: category.isActive
                                                ? const Color(0xFF1D7A46)
                                                : const Color(0xFFB42318),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      '${category.catalogItemsCount} خدمة أو بكج',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_left_rounded,
                                color: secondary,
                              ),
                            ],
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

  Widget _messageState({
    required IconData icon,
    required String title,
    required Color primary,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: primary),
          ),
          if (onPressed != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({
    required this.isDarkMode,
    required this.departmentId,
    this.category,
  });

  final bool isDarkMode;
  final int departmentId;
  final AdminCategory? category;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  static const _gold = Color(0xFFB89552);

  final _formKey = GlobalKey<FormState>();
  final _service = const AdminCategoryService();
  final _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _description;

  XFile? _newImage;
  bool _active = true;
  bool _saving = false;
  bool _removeExisting = false;

  bool get _editing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _active = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );

    if (image == null || !mounted) return;
    setState(() {
      _newImage = image;
      _removeExisting = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_editing) {
        await _service.updateCategory(
          categoryId: widget.category!.id,
          departmentId: widget.departmentId,
          name: _name.text,
          description: _description.text,
          isActive: _active,
          imagePath: _newImage?.path,
        );

        if (_removeExisting && _newImage == null) {
          await _service.deleteImage(widget.category!.id);
        }
      } else {
        await _service.createCategory(
          departmentId: widget.departmentId,
          name: _name.text,
          description: _description.text,
          isActive: _active,
          imagePath: _newImage?.path,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } on AdminCategoryException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _show(error.message);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف التصنيف'),
          content: const Text(
            'لا يمكن حذف التصنيف إذا كان مرتبطًا بخدمات أو بكجات.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await _service.deleteCategory(widget.category!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on AdminCategoryException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _show(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark ? Colors.black : Colors.white;
    final primary = dark ? Colors.white : const Color(0xFF171717);
    final secondary = dark ? const Color(0xFFC2C2C2) : const Color(0xFF666666);
    final border = dark ? const Color(0xFF3D3D3D) : const Color(0xFFD7D7D7);

    return Material(
      color: background,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _editing ? 'تعديل التصنيف' : 'إضافة تصنيف جديد',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      _imagePreview(),
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: FloatingActionButton.small(
                          heroTag: null,
                          onPressed: _pickImage,
                          backgroundColor: _gold,
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_newImage != null ||
                    (widget.category?.imageUrl != null && !_removeExisting))
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_newImage != null) {
                            _newImage = null;
                          } else {
                            _removeExisting = true;
                          }
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('حذف الصورة'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  decoration: _decoration('اسم التصنيف', border),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اسم التصنيف مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _decoration('الوصف - اختياري', border),
                ),
                SwitchListTile.adaptive(
                  value: _active,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _active = value),
                  activeColor: _gold,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'التصنيف نشط',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _active ? 'يظهر داخل التطبيق.' : 'مخفي عن الزبائن.',
                    style: TextStyle(color: secondary),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: dark
                        ? const Color(0xFFD3B06B)
                        : const Color(0xFF171717),
                    foregroundColor: dark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(
                          _editing ? 'حفظ التعديلات' : 'إضافة التصنيف',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
                if (_editing) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف التصنيف'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: const Color(0xFFB42318),
                      side: const BorderSide(color: Color(0xFFB42318)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePreview() {
    if (_newImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.file(
          File(_newImage!.path),
          width: 132,
          height: 132,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.category?.imageUrl != null && !_removeExisting) {
      return _CategoryImage(url: widget.category!.imageUrl, size: 132);
    }

    return Container(
      width: 132,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        color: _gold,
        size: 40,
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

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFB89552).withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(size > 100 ? 22 : 15),
        ),
        child: const Icon(
          Icons.category_outlined,
          color: Color(0xFFB89552),
          size: 28,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 100 ? 22 : 15),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: const Color(0xFFB89552).withValues(alpha: 0.13),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFB89552),
          ),
        ),
      ),
    );
  }
}
