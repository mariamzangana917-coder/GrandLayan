import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/gl_network_image.dart';
import '../../../catalog/data/models/catalog_item.dart';

class SalonServiceCard extends StatelessWidget {
  const SalonServiceCard({required this.item, required this.onTap, super.key});

  final CatalogItem item;
  final VoidCallback onTap;

  String get _priceText {
    if (item.priceType == 'inspection') {
      return 'السعر بعد المعاينة';
    }

    return PriceFormatter.formatIqd(item.price);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final String description = item.description?.trim() ?? '';

    const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(16));

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: cardBorderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.045),
            blurRadius: 3.5,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.18),
            blurRadius: 2.5,
            spreadRadius: 0,
            offset: const Offset(0, 2.5),
          ),
        ],
      ),
      child: Material(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        borderRadius: cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          child: SizedBox(
            height: 126,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 108,
                      height: 108,
                      child: GlNetworkImage(
                        imageUrl: item.primaryImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 15.5,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (description.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 7),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            _priceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Color(0xFFC9A227),
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
