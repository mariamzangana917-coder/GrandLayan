class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> validationErrors;

  String? firstErrorFor(String field) {
    final errors = validationErrors[field];

    if (errors == null || errors.isEmpty) {
      return null;
    }

    return errors.first;
  }

  @override
  String toString() => message;
}
