import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import 'manager_profile_model.dart';

class ManagerProfileService {
  ManagerProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<ManagerProfile> fetchProfile() async {
    final Response<dynamic> response = await _apiClient.get('/auth/me');

    return _readProfile(_responseBody(response));
  }

  Future<ManagerProfile> updateProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    final Response<dynamic> response = await _apiClient.put(
      '/auth/profile',
      data: <String, dynamic>{
        'name': name.trim(),
        'phone': _normalizePhone(phone),
        'email': email.trim().toLowerCase(),
      },
    );

    return _readProfile(_responseBody(response));
  }

  Future<ManagerProfile> updateAvatar({required File image}) async {
    if (!await image.exists()) {
      throw const ApiException(message: 'الصورة المختارة غير موجودة.');
    }

    final String fileName = image.path.split(Platform.pathSeparator).last;

    final FormData formData = FormData.fromMap(<String, dynamic>{
      'avatar': await MultipartFile.fromFile(image.path, filename: fileName),
    });

    final Response<dynamic> response = await _apiClient.post(
      '/auth/profile/avatar',
      data: formData,
    );

    return _readProfile(_responseBody(response));
  }

  Future<ManagerProfile> deleteAvatar() async {
    final Response<dynamic> response = await _apiClient.delete(
      '/auth/profile/avatar',
    );

    return _readProfile(_responseBody(response));
  }

  Map<String, dynamic> _responseBody(Response<dynamic> response) {
    final Object? body = response.data;

    if (body is Map<String, dynamic>) {
      return body;
    }

    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }

    throw const FormatException('استجابة الخادم غير صالحة.');
  }

  ManagerProfile _readProfile(Map<String, dynamic> response) {
    final Map<String, dynamic>? data = _asStringMap(response['data']);

    if (data != null) {
      final Map<String, dynamic>? user = _asStringMap(data['user']);

      if (user != null) {
        return _withResolvedAvatar(ManagerProfile.fromJson(user));
      }

      if (_looksLikeProfile(data)) {
        return _withResolvedAvatar(ManagerProfile.fromJson(data));
      }
    }

    final Map<String, dynamic>? user = _asStringMap(response['user']);

    if (user != null) {
      return _withResolvedAvatar(ManagerProfile.fromJson(user));
    }

    if (_looksLikeProfile(response)) {
      return _withResolvedAvatar(ManagerProfile.fromJson(response));
    }

    throw const FormatException('استجابة بيانات حساب المديرة غير صالحة.');
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  ManagerProfile _withResolvedAvatar(ManagerProfile profile) {
    final String? avatar = profile.avatar;

    if (avatar == null || avatar.trim().isEmpty) {
      return profile;
    }

    final String cleanAvatar = avatar.trim();

    if (cleanAvatar.startsWith('http://') ||
        cleanAvatar.startsWith('https://')) {
      return profile;
    }

    final Uri apiUri = Uri.parse(ApiConfig.baseUrl);

    final String origin = apiUri
        .replace(path: '', query: null, fragment: null)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');

    final String cleanPath = cleanAvatar.startsWith('/')
        ? cleanAvatar.substring(1)
        : cleanAvatar;

    final String resolved = cleanPath.startsWith('storage/')
        ? '$origin/$cleanPath'
        : '$origin/storage/$cleanPath';

    return profile.copyWith(avatar: resolved);
  }

  bool _looksLikeProfile(Map<String, dynamic> json) {
    return json.containsKey('id') &&
        json.containsKey('name') &&
        json.containsKey('email') &&
        json.containsKey('phone');
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-()]'), '').trim();
  }
}
