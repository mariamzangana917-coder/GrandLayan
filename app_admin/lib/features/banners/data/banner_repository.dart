import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'admin_banner.dart';

class BannerRepository {
  const BannerRepository();

  Future<List<AdminBanner>> fetch() async {
    try {
      final response = await ApiClient.dio.get<dynamic>('/admin/banners');
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data is! List) throw const FormatException();
      return data.whereType<Map>().map((value) => AdminBanner.fromJson(Map<String, dynamic>.from(value))).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AdminBanner> save({AdminBanner? existing, required Map<String, dynamic> fields, File? image}) async {
    try {
      final data = FormData.fromMap(<String, dynamic>{
        ...fields,
        if (existing != null) '_method': 'PUT',
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
      });
      final response = await ApiClient.dio.post<dynamic>(
        existing == null ? '/admin/banners' : '/admin/banners/${existing.id}',
        data: data,
      );
      final root = response.data;
      if (root is! Map || root['data'] is! Map) throw const FormatException();
      return AdminBanner.fromJson(Map<String, dynamic>.from(root['data'] as Map));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await ApiClient.dio.delete<dynamic>('/admin/banners/$id');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
