import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'catalog_create_screen.dart';
import 'catalog_details_screen.dart';
import 'data/catalog_models.dart';
import 'data/catalog_service.dart';

enum DepartmentFilter { salon, clinic }

enum TypeFilter { all, service, package }

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CatalogService _service = const CatalogService();
  final TextEditingController _search = TextEditingController();

  DepartmentFilter _department = DepartmentFilter.salon;
  TypeFilter _type = TypeFilter.all;

  List<CatalogItem> _allItems = [];
  List<CatalogItem> _items = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _service.fetchItems(
        department: _departmentCode,
        type: _typeCode,
        search: _search.text,
      );

      if (!mounted) return;

      setState(() {
        _allItems = page.items;
        _loading = false;
      });

      _applySearch();
    } on CatalogException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  String get _departmentCode =>
      _department == DepartmentFilter.salon ? 'salon' : 'clinic';

  String? get _typeCode {
    return switch (_type) {
      TypeFilter.all => null,
      TypeFilter.service => 'service',
      TypeFilter.package => 'package',
    };
  }

  void _onSearch(String _) {
    _applySearch();
  }

  void _applySearch() {
    final query = _normalizeArabic(_search.text);

    final filtered = _allItems.where((item) {
      if (item.departmentCode != _departmentCode) {
        return false;
      }

      if (_typeCode != null && item.type != _typeCode) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = _normalizeArabic(item.name);
      final category = _normalizeArabic(item.categoryName);
      final description = _normalizeArabic(item.description ?? '');

      return name.startsWith(query) ||
          name.contains(query) ||
          category.startsWith(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aName = _normalizeArabic(a.name);
      final bName = _normalizeArabic(b.name);

      final aStarts = aName.startsWith(query);
      final bStarts = bName.startsWith(query);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return aName.compareTo(bName);
    });

    if (!mounted) return;

    setState(() {
      _items = filtered;
    });
  }

  String _normalizeArabic(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ـ', '');
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CatalogCreateScreen(
          isDarkMode: widget.isDarkMode,
          initialDepartmentCode: _departmentCode,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _openDetails(CatalogItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CatalogDetailsScreen(
          itemId: item.id,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = dark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final secondary = dark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'الخدمات والبكجات',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
            children: [
              TextField(
                controller: _search,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'ابحثي باسم الخدمة أو التصنيف',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_search.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _search.clear();
                            _applySearch();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      Container(width: 1, height: 28, color: border),
                      PopupMenuButton<TypeFilter>(
                        initialValue: _type,
                        onSelected: (value) {
                          setState(() {
                            _type = value;
                          });
                          _load();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: TypeFilter.all,
                            child: Text('الكل'),
                          ),
                          PopupMenuItem(
                            value: TypeFilter.service,
                            child: Text('الخدمات'),
                          ),
                          PopupMenuItem(
                            value: TypeFilter.package,
                            child: Text('البكجات'),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Text(
                            switch (_type) {
                              TypeFilter.all => 'الكل',
                              TypeFilter.service => 'الخدمات',
                              TypeFilter.package => 'البكجات',
                            },
                            style: TextStyle(
                              color: primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  PopupMenuButton<DepartmentFilter>(
                    initialValue: _department,
                    onSelected: (value) {
                      setState(() {
                        _department = value;
                      });
                      _load();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: DepartmentFilter.salon,
                        child: Text('الصالون'),
                      ),
                      PopupMenuItem(
                        value: DepartmentFilter.clinic,
                        child: Text('العيادة'),
                      ),
                    ],
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _department == DepartmentFilter.salon
                              ? 'الصالون'
                              : 'العيادة',
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
                  Text(
                    '${_items.length} عنصر',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                )
              else if (_error != null)
                _errorState(primary)
              else if (_items.isEmpty)
                _emptyState(primary, secondary)
              else
                ..._items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openDetails(item),
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              _image(item, surface),
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
                                            item.name,
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: primary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        _status(item.isActive),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.categoryName,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          item.isPackage ? 'بكج' : 'خدمة',
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _price(item),
                                          style: TextStyle(
                                            color: primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 66,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
      ),
    );
  }

  Widget _image(CatalogItem item, Color surface) {
    final image = item.mainImage;

    if (image == null || image.url.isEmpty) {
      return Container(
        width: 66,
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          item.isPackage ? Icons.inventory_2_outlined : Icons.spa_outlined,
          color: AppColors.gold,
          size: 27,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        image.url,
        width: 66,
        height: 66,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            color: surface,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.gold,
            ),
          );
        },
      ),
    );
  }

  Widget _status(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? AppColors.success : AppColors.error).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        active ? 'نشط' : 'غير نشط',
        style: TextStyle(
          color: active ? AppColors.success : AppColors.error,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _errorState(Color primary) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: primary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(Color primary, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, color: AppColors.gold, size: 38),
          const SizedBox(height: 10),
          Text(
            'لا توجد نتائج',
            style: TextStyle(color: primary, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'غيّري البحث أو الفلاتر.',
            style: TextStyle(color: secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _price(CatalogItem item) {
    if (item.priceType == 'inspection' || item.price == null) {
      return 'بعد المعاينة';
    }

    final value = item.price! % 1 == 0
        ? item.price!.toInt().toString()
        : item.price!.toStringAsFixed(2);

    return '$value د.ع';
  }
}
