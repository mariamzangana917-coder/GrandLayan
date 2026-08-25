import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/gl_empty_state.dart';
import '../../../shared/widgets/gl_error_state.dart';
import '../../../shared/widgets/gl_loading.dart';
import '../../catalog/data/models/catalog_item.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../salon/presentation/widgets/salon_service_card.dart';
import 'clinic_service_details_page.dart';

class ClinicCategoryPage extends ConsumerStatefulWidget {
  const ClinicCategoryPage({
    required this.categoryId,
    required this.categoryName,
    super.key,
  });

  final int categoryId;
  final String categoryName;

  @override
  ConsumerState<ClinicCategoryPage> createState() => _ClinicCategoryPageState();
}

class _ClinicCategoryPageState extends ConsumerState<ClinicCategoryPage> {
  late final CatalogFilter _filter;

  @override
  void initState() {
    super.initState();

    _filter = CatalogFilter(
      department: 'clinic',
      categoryId: widget.categoryId,
    );
  }

  Future<void> _refresh() {
    return ref.refresh(catalogItemsProvider(_filter).future);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    final AsyncValue<List<CatalogItem>> catalogState = ref.watch(
      catalogItemsProvider(_filter),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.categoryName,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFC9A227),
        onRefresh: _refresh,
        child: catalogState.when(
          loading: () => const _ScrollableState(
            child: GlLoading(message: 'جاري تحميل الخدمات...'),
          ),
          error: (Object error, StackTrace stackTrace) {
            return _ScrollableState(
              child: GlErrorState(
                message:
                    'تعذر تحميل الخدمات. تأكدي من اتصال الخادم ثم أعيدي المحاولة.',
                onRetry: () {
                  ref.invalidate(catalogItemsProvider(_filter));
                },
              ),
            );
          },
          data: (List<CatalogItem> items) {
            final List<CatalogItem> visibleItems = items
                .where((CatalogItem item) => item.isActive && item.isService)
                .toList(growable: false);

            if (visibleItems.isEmpty) {
              return const _ScrollableState(
                child: GlEmptyState(
                  title: 'لا توجد خدمات حاليًا',
                  message:
                      'ستظهر خدمات هذا التصنيف بعد إضافتها من تطبيق الإدارة.',
                  icon: Icons.medical_services_outlined,
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              itemCount: visibleItems.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 16);
              },
              itemBuilder: (BuildContext context, int index) {
                final CatalogItem item = visibleItems[index];

                return SalonServiceCard(
                  item: item,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return ClinicServiceDetailsPage(item: item);
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ScrollableState extends StatelessWidget {
  const _ScrollableState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        );
      },
    );
  }
}
