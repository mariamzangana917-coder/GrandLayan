import 'package:flutter/material.dart';

import '../../catalog/data/models/catalog_item.dart';
import '../../salon/presentation/salon_service_details_page.dart';

class ClinicServiceDetailsPage extends StatelessWidget {
  const ClinicServiceDetailsPage({
    required this.item,
    super.key,
    this.originalPrice,
    this.onFavoriteChanged,
  });

  final CatalogItem item;
  final num? originalPrice;
  final Future<void> Function(bool isFavorite)? onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    return SalonServiceDetailsPage(
      item: item,
      originalPrice: originalPrice,
      onFavoriteChanged: onFavoriteChanged,
    );
  }
}
