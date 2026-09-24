class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException({required this.message, this.statusCode});
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'خطا در اتصال به شبکه'});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'دسترسی غیرمجاز'});
}