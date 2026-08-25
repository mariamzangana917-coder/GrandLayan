import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/data/repositories/catalog_repository.dart';
import '../../clinic/presentation/clinic_category_page.dart';
import '../../clinic/presentation/clinic_service_details_page.dart';
import '../../salon/presentation/salon_category_page.dart';
import '../../salon/presentation/salon_service_details_page.dart';
import '../data/customer_banner.dart';

abstract final class BannerNavigator {
  static Future<void> open(
    BuildContext context,
    CustomerBanner banner,
  ) async {
    try {
      switch (banner.actionType) {
        case 'none':
          return;
case 'offers':
  if (banner.placement == 'home') {
    context.pushNamed('offers');
  } else {
    context.pushNamed(
      'offers',
      queryParameters: <String, dynamic>{
        'department': banner.placement,
      },
    );
  }
  return;

        case 'gift_card':
          context.pushNamed('gift-cards');
          return;

        case 'category':
          await _openCategory(context, banner.actionTargetId);
          return;

        case 'catalog_item':
          await _openItem(context, banner.actionTargetId);
          return;

        case 'department':
          await _openDepartment(context, banner.actionTargetId);
          return;

        default:
          return;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح وجهة البانر.'),
          ),
        );
      }
    }
  }

  static Future<void> _openDepartment(
    BuildContext context,
    int? id,
  ) async {
    if (id == null) {
      return;
    }

    final items = await CatalogRepository().getCatalogItems();

    final item = items
        .where((value) => value.department?.id == id)
        .firstOrNull;

    if (item == null || !context.mounted) {
      return;
    }

    final departmentCode = item.department?.code;

    if (departmentCode == null) {
      return;
    }

    _goDepartment(context, departmentCode);
  }

  static Future<void> _openCategory(
    BuildContext context,
    int? id,
  ) async {
    if (id == null) {
      return;
    }

    final items = await CatalogRepository().getCatalogItems();

    final item = items
        .where((value) => value.category?.id == id)
        .firstOrNull;

    if (item == null || !context.mounted) {
      return;
    }

    final category = item.category;

    if (category == null) {
      return;
    }

    final departmentCode = item.department?.code;

    if (departmentCode == 'salon') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SalonCategoryPage(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
      );
      return;
    }

    if (departmentCode == 'clinic') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClinicCategoryPage(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
      );
      return;
    }
  }

  static Future<void> _openItem(
    BuildContext context,
    int? id,
  ) async {
    if (id == null) {
      return;
    }

    final item = await CatalogRepository().getCatalogItem(id);

    if (!context.mounted || !item.isActive) {
      return;
    }

    final departmentCode = item.department?.code;

    if (departmentCode == 'salon') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SalonServiceDetailsPage(
            item: item,
          ),
        ),
      );
      return;
    }

    if (departmentCode == 'clinic') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClinicServiceDetailsPage(
            item: item,
          ),
        ),
      );
      return;
    }
  }

  static void _goDepartment(
    BuildContext context,
    String code,
  ) {
    if (code == 'salon' || code == 'clinic') {
      context.pushNamed(code);
    }
  }
}