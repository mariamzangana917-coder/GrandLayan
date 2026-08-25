import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/favorite_item.dart';
import '../data/repositories/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepository(),
);

final favoritesProvider = FutureProvider<List<FavoriteItem>>((ref) async {
  final FavoriteRepository repository = ref.watch(favoriteRepositoryProvider);

  return repository.getFavorites();
});
