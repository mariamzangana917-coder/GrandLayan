import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog_item.dart';
import '../repositories/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => const CatalogRepository(),
);

class CatalogFilter {
  const CatalogFilter({
    this.department,
    this.categoryId,
    this.type,
  });

  final String? department;
  final int? categoryId;
  final String? type;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CatalogFilter &&
        other.department == department &&
        other.categoryId == categoryId &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(
        department,
        categoryId,
        type,
      );
}

final catalogItemsProvider =
    FutureProvider.family<List<CatalogItem>, CatalogFilter>(
  (ref, filter) async {
    final repository = ref.watch(catalogRepositoryProvider);

    return repository.getCatalogItems(
      department: filter.department,
      categoryId: filter.categoryId,
      type: filter.type,
    );
  },
);

final catalogItemDetailsProvider =
    FutureProvider.family<CatalogItem, int>(
  (ref, catalogItemId) async {
    final repository = ref.watch(catalogRepositoryProvider);

    return repository.getCatalogItem(catalogItemId);
  },
);

final salonCatalogProvider = FutureProvider<List<CatalogItem>>(
  (ref) {
    return ref.watch(
      catalogItemsProvider(
        const CatalogFilter(
          department: 'salon',
        ),
      ).future,
    );
  },
);

final clinicCatalogProvider = FutureProvider<List<CatalogItem>>(
  (ref) {
    return ref.watch(
      catalogItemsProvider(
        const CatalogFilter(
          department: 'clinic',
        ),
      ).future,
    );
  },
);