abstract final class ApiUrl {
  static const String serverUrl = 'http://64.227.16.105';

  static String? resolveStorageUrl(String? value) {
    final String path = value?.trim() ?? '';

    if (path.isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    String normalizedPath = path;

    while (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    if (normalizedPath.startsWith('storage/')) {
      return '$serverUrl/$normalizedPath';
    }

    return '$serverUrl/storage/$normalizedPath';
  }

  const ApiUrl._();
}
