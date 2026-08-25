import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../catalog/categories/admin_category_model.dart';
import '../../catalog/categories/admin_category_service.dart';
import '../../catalog/data/catalog_item.dart';
import '../../catalog/data/repositories/catalog_repository.dart';
import '../data/admin_banner.dart';
import '../data/banner_repository.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  final BannerRepository _repository = const BannerRepository();
  late Future<List<AdminBanner>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetch();
  }

  void _reload() {
    setState(() {
      _future = _repository.fetch();
    });
  }

  Future<void> _openForm([AdminBanner? banner]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _BannerFormScreen(isDarkMode: widget.isDarkMode, banner: banner),
      ),
    );

    if (changed == true && mounted) {
      _reload();
    }
  }

  Future<void> _delete(AdminBanner banner) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف البانر؟'),
        content: const Text('سيتم حذف البانر وصورته نهائيًا.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (approved != true || !mounted) {
      return;
    }

    try {
      await _repository.delete(banner.id);

      if (mounted) {
        _reload();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('البانرات'),
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('إضافة بانر'),
      ),
      body: FutureBuilder<List<AdminBanner>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _reload,
                child: const Text('تعذر تحميل البانرات. إعادة المحاولة'),
              ),
            );
          }

          final items = snapshot.data ?? const <AdminBanner>[];

          if (items.isEmpty) {
            return const Center(child: Text('لا توجد بانرات بعد.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final banner = items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        banner.imageUrl,
                        width: 76,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 76,
                            child: Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
                    ),
                    title: Text(banner.title ?? 'بانر ${banner.id}'),
                    subtitle: Text(
                      '${_placementLabel(banner.placement)} • '
                      'ترتيب ${banner.sortOrder} • '
                      '${banner.isActive ? 'نشط' : 'متوقف'}\n'
                      '${_actionLabel(banner.actionType)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openForm(banner);
                        } else if (value == 'delete') {
                          _delete(banner);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BannerFormScreen extends StatefulWidget {
  const _BannerFormScreen({required this.isDarkMode, this.banner});

  final bool isDarkMode;
  final AdminBanner? banner;

  @override
  State<_BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<_BannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = const BannerRepository();
  final _catalogRepository = const CatalogRepository();
  final _categoryService = const AdminCategoryService();
  final _picker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _order;

  late String _placement;
  late String _uiAction;
  late bool _active;

  int? _selectedTargetId;
  String? _selectedTargetLabel;

  File? _image;
  bool _saving = false;
  bool _resolvingTarget = false;

  @override
  void initState() {
    super.initState();

    final banner = widget.banner;

    _title = TextEditingController(text: banner?.title ?? '');
    _subtitle = TextEditingController(text: banner?.subtitle ?? '');
    _order = TextEditingController(text: banner?.sortOrder.toString() ?? '0');
    _placement = banner?.placement ?? 'home';
    _active = banner?.isActive ?? true;
    _selectedTargetId = banner?.actionTargetId;
    _uiAction = _uiActionFromBackend(banner?.actionType ?? 'none');

    if (_needsTarget && _selectedTargetId != null) {
      _resolvingTarget = true;
      _resolveExistingTargetLabel();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _order.dispose();
    super.dispose();
  }

  bool get _needsTarget =>
      _uiAction == 'service' ||
      _uiAction == 'package' ||
      _uiAction == 'category';

  Future<void> _resolveExistingTargetLabel() async {
    try {
      if (_uiAction == 'service' || _uiAction == 'package') {
        final item = await _catalogRepository.getCatalogItem(
          _selectedTargetId!,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _uiAction = item.isPackage ? 'package' : 'service';
          _selectedTargetLabel = item.name;
          _resolvingTarget = false;
        });
        return;
      }

      if (_uiAction == 'category') {
        final categories = await _loadCategories();
        final match = categories
            .where((category) => category.id == _selectedTargetId)
            .firstOrNull;
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedTargetLabel = match == null
              ? 'تصنيف #$_selectedTargetId'
              : '${match.name} (${_departmentLabel(match.departmentCode)})';
          _resolvingTarget = false;
        });
        return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTargetLabel = 'عنصر #$_selectedTargetId';
        _resolvingTarget = false;
      });
    }
  }

  Future<List<AdminCategory>> _loadCategories() async {
    final salon = await _categoryService.fetchCategories('salon');
    final clinic = await _categoryService.fetchCategories('clinic');
    return [...salon, ...clinic];
  }

  Future<void> _pick() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked != null && mounted) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _pickCatalogItem({required bool packages}) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final items = await _catalogRepository.getCatalogItems(
        type: packages ? 'package' : 'service',
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();

      final activeItems = items.where((item) => item.isActive).toList();
      if (activeItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              packages ? 'لا توجد بكجات متاحة.' : 'لا توجد خدمات متاحة.',
            ),
          ),
        );
        return;
      }

      final selected = await showModalBottomSheet<CatalogItem>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      packages ? 'اختيار بكج' : 'اختيار خدمة',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: activeItems.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = activeItems[index];
                        final categoryName = item.category?.name;
                        return ListTile(
                          title: Text(item.name),
                          subtitle: categoryName == null
                              ? null
                              : Text(categoryName),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (selected == null || !mounted) {
        return;
      }

      setState(() {
        _selectedTargetId = selected.id;
        _selectedTargetLabel = selected.name;
      });
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _pickCategory() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final categories = await _loadCategories();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();

      final active = categories.where((category) => category.isActive).toList();
      if (active.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد تصنيفات متاحة.')),
        );
        return;
      }

      final selected = await showModalBottomSheet<AdminCategory>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'اختيار تصنيف',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: active.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = active[index];
                        return ListTile(
                          title: Text(category.name),
                          subtitle: Text(
                            _departmentLabel(category.departmentCode),
                          ),
                          onTap: () => Navigator.pop(context, category),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (selected == null || !mounted) {
        return;
      }

      setState(() {
        _selectedTargetId = selected.id;
        _selectedTargetLabel =
            '${selected.name} (${_departmentLabel(selected.departmentCode)})';
      });
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.banner == null && _image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('صورة البانر مطلوبة.')));
      return;
    }

    if (_needsTarget && _selectedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _uiAction == 'category'
                ? 'يجب اختيار تصنيف.'
                : _uiAction == 'package'
                ? 'يجب اختيار بكج.'
                : 'يجب اختيار خدمة.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final mapped = _mapUiActionToApi(_uiAction);

      await _repository.save(
        existing: widget.banner,
        image: _image,
        fields: {
          'title': _null(_title.text),
          'subtitle': _null(_subtitle.text),
          'placement': _placement,
          'action_type': mapped.actionType,
          'action_target_id': mapped.needsTarget
              ? _selectedTargetId
              : '',
          'sort_order': int.parse(_order.text),
          'is_active': _active ? 1 : 0,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banner == null ? 'إضافة بانر' : 'تعديل البانر'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InkWell(
              onTap: _pick,
              child: Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _image != null
                    ? Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : widget.banner?.imageUrl.isNotEmpty == true
                    ? Image.network(
                        widget.banner!.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 38),
                          SizedBox(height: 8),
                          Text('اختيار صورة'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            _field(_title, 'العنوان (اختياري)'),
            _field(_subtitle, 'الوصف (اختياري)'),
            DropdownButtonFormField<String>(
              value: _placement,
              decoration: const InputDecoration(labelText: 'مكان الظهور'),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('الرئيسية')),
                DropdownMenuItem(value: 'salon', child: Text('الصالون')),
                DropdownMenuItem(value: 'clinic', child: Text('العيادة')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _placement = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _uiAction,
              decoration: const InputDecoration(labelText: 'الإجراء عند الضغط'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('بدون إجراء')),
                DropdownMenuItem(value: 'offers', child: Text('العروض')),
                DropdownMenuItem(value: 'service', child: Text('خدمة')),
                DropdownMenuItem(value: 'package', child: Text('بكج')),
                DropdownMenuItem(value: 'gift_card', child: Text('بطاقة هدية')),
                DropdownMenuItem(value: 'category', child: Text('تصنيف')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _uiAction = value;
                  if (!_needsTarget) {
                    _selectedTargetId = null;
                    _selectedTargetLabel = null;
                  } else {
                    _selectedTargetId = null;
                    _selectedTargetLabel = null;
                  }
                });
              },
            ),
            if (_needsTarget) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: _uiAction == 'category'
                      ? 'التصنيف المختار'
                      : _uiAction == 'package'
                      ? 'البكج المختار'
                      : 'الخدمة المختارة',
                  border: const OutlineInputBorder(),
                ),
                child: _resolvingTarget
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedTargetLabel ?? 'لم يتم الاختيار بعد',
                              style: TextStyle(
                                color: _selectedTargetLabel == null
                                    ? Theme.of(context).hintColor
                                    : null,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_uiAction == 'category') {
                                _pickCategory();
                              } else {
                                _pickCatalogItem(
                                  packages: _uiAction == 'package',
                                );
                              }
                            },
                            child: Text(
                              _selectedTargetId == null ? 'اختيار' : 'تغيير',
                            ),
                          ),
                        ],
                      ),
              ),
            ],
            const SizedBox(height: 12),
            _field(_order, 'ترتيب العرض', numeric: true, required: true),
            SwitchListTile(
              value: _active,
              title: const Text('بانر نشط'),
              onChanged: (value) {
                setState(() {
                  _active = value;
                });
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ البانر'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'هذا الحقل مطلوب';
          }

          if (numeric &&
              value != null &&
              value.trim().isNotEmpty &&
              int.tryParse(value.trim()) == null) {
            return 'أدخلي رقمًا صحيحًا';
          }

          return null;
        },
      ),
    );
  }

  String? _null(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

class _MappedAction {
  const _MappedAction({required this.actionType, required this.needsTarget});

  final String actionType;
  final bool needsTarget;
}

_MappedAction _mapUiActionToApi(String uiAction) {
  switch (uiAction) {
    case 'service':
    case 'package':
      return const _MappedAction(actionType: 'catalog_item', needsTarget: true);
    case 'category':
      return const _MappedAction(actionType: 'category', needsTarget: true);
    case 'offers':
      return const _MappedAction(actionType: 'offers', needsTarget: false);
    case 'gift_card':
      return const _MappedAction(actionType: 'gift_card', needsTarget: false);
    case 'none':
    default:
      return const _MappedAction(actionType: 'none', needsTarget: false);
  }
}

String _uiActionFromBackend(String actionType) {
  switch (actionType) {
    case 'offers':
      return 'offers';
    case 'gift_card':
      return 'gift_card';
    case 'category':
      return 'category';
    case 'catalog_item':
      return 'service';
    case 'none':
    default:
      return 'none';
  }
}

String _placementLabel(String value) {
  return {'home': 'الرئيسية', 'salon': 'الصالون', 'clinic': 'العيادة'}[value] ??
      value;
}

String _departmentLabel(String code) {
  return {'salon': 'الصالون', 'clinic': 'العيادة'}[code] ?? code;
}

String _actionLabel(String value) {
  return {
        'none': 'بدون إجراء',
        'offers': 'العروض',
        'catalog_item': 'خدمة / بكج',
        'gift_card': 'بطاقة هدية',
        'category': 'تصنيف',
        'department': 'قسم',
        'booking': 'حجز',
        'external_url': 'رابط خارجي',
      }[value] ??
      value;
}
