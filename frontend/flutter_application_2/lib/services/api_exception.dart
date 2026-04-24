class ApiException implements Exception {
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
