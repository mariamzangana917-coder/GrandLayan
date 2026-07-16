import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'catalog_edit_screen.dart';
import 'data/catalog_models.dart';
import 'data/catalog_service.dart';

class CatalogDetailsScreen extends StatefulWidget {
  const CatalogDetailsScreen({
    required this.itemId,
    required this.isDarkMode,
    super.key,
  });

  final int itemId;
  final bool isDarkMode;

  @override
  State<CatalogDetailsScreen> createState() =>
      _CatalogDetailsScreenState();
}

class _CatalogDetailsScreenState
    extends State<CatalogDetailsScreen> {
  final CatalogService _service = const CatalogService();

  CatalogItem? _item;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await _service.fetchItem(widget.itemId);

      if (!mounted) return;

      setState(() {
        _item = item;
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
          'تفاصيل الخدمة',
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
                ? _errorState(primary)
                : _content(
                    item: _item!,
                    surface: surface,
                    primary: primary,
                    secondary: secondary,
                    border: border,
                  ),
      ),
      bottomNavigationBar: _item == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12,
                ),
                child: FilledButton.icon(
                  onPressed: _openEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _content({
    required CatalogItem item,
    required Color surface,
    required Color primary,
    required Color secondary,
    required Color border,
  }) {
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          24,
        ),
        children: [
          if (item.images.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: item.images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      item.images[index].url,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return _imageFallback(surface);
                      },
                    ),
                  );
                },
              ),
            )
          else
            _imageFallback(surface),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(item.isActive),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.departmentName} • ${item.categoryName}',
            style: TextStyle(
              color: secondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          _infoCard(
            surface: surface,
            border: border,
            children: [
              _row(
                'النوع',
                item.isPackage ? 'بكج' : 'خدمة',
                primary,
                secondary,
              ),
              _row(
                'السعر',
                _price(item),
                primary,
                secondary,
              ),
              _row(
                'المدة',
                item.durationMinutes == null
                    ? 'غير محددة'
                    : '${item.durationMinutes} دقيقة',
                primary,
                secondary,
              ),
            ],
          ),
          if (item.description != null) ...[
            const SizedBox(height: 14),
            _section(
              'الوصف',
              item.description!,
              surface,
              border,
              primary,
              secondary,
            ),
          ],
          if (item.instructions != null) ...[
            const SizedBox(height: 14),
            _section(
              'تعليمات قبل الخدمة',
              item.instructions!,
              surface,
              border,
              primary,
              secondary,
            ),
          ],
          if (item.isPackage) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'محتويات البكج',
                    style: TextStyle(
                      color: primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.packageItems.isEmpty)
                    Text(
                      'لا توجد خدمات مضافة.',
                      style: TextStyle(color: secondary),
                    )
                  else
                    ...item.packageItems.map(
                      (packageItem) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.gold,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                packageItem.serviceName,
                                style: TextStyle(
                                  color: primary,
                                ),
                              ),
                            ),
                            Text(
                              '×${packageItem.quantity}',
                              style: TextStyle(
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imageFallback(Color surface) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.gold,
        size: 52,
      ),
    );
  }

  Widget _infoCard({
    required Color surface,
    required Color border,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(children: children),
    );
  }

  Widget _section(
    String title,
    String body,
    Color surface,
    Color border,
    Color primary,
    Color secondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: TextStyle(
              color: secondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    Color primary,
    Color secondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: secondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: (active
                ? AppColors.success
                : AppColors.error)
            .withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'نشط' : 'غير نشط',
        style: TextStyle(
          color: active
              ? AppColors.success
              : AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _errorState(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
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

  String _price(CatalogItem item) {
    if (item.priceType == 'inspection' ||
        item.price == null) {
      return 'بعد المعاينة';
    }

    final value = item.price! % 1 == 0
        ? item.price!.toInt().toString()
        : item.price!.toStringAsFixed(2);

    return '$value د.ع';
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CatalogEditScreen(
          item: _item!,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
