import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/catalog_item.dart';
import '../data/repositories/catalog_repository.dart';

final catalogRepositoryProvider =
    Provider<CatalogRepository>(
  (ref) => CatalogRepository(),
);

final catalogItemsProvider =
    FutureProvider.family<
        List<CatalogItem>,
        CatalogFilter>(
  (ref, filter) async {
    final repository = ref.watch(
      catalogRepositoryProvider,
    );

    return repository.getCatalogItems(
      department: filter.department,
      categoryId: filter.categoryId,
      type: filter.type,
    );
  },
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
}