import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post_model.dart';
import '../data/repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(),
);

final postsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, department) async {
  final repository = ref.watch(postRepositoryProvider);

  return repository.getPosts(
    department: department,
  );
});
