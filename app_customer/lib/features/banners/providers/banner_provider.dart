import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/banner_repository.dart';
import '../data/customer_banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) => BannerRepository());
final bannersProvider = FutureProvider.family<List<CustomerBanner>, String>((ref, placement) => ref.watch(bannerRepositoryProvider).fetch(placement));
