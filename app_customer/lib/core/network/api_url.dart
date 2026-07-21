abstract final class ApiUrl {
  static const String baseUrl = 'http://64.227.16.105';

  static String? resolveStorageUrl(String? value) {
    final String path = value?.trim() ?? '';

    if (path.isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    if (cleanPath.startsWith('storage/')) {
      return '$baseUrl/$cleanPath';
    }

    return '$baseUrl/storage/$cleanPath';
  }

  const ApiUrl._();
}
