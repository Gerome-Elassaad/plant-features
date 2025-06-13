class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, [this.code]);
  
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred']) : super(message, 'NETWORK_ERROR');
}

class ServerException extends AppException {
  ServerException([String message = 'Server error occurred']) : super(message, 'SERVER_ERROR');
}

class BadRequestException extends AppException {
  BadRequestException([String message = 'Invalid request']) : super(message, 'BAD_REQUEST');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message, 'UNAUTHORIZED');
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found']) : super(message, 'NOT_FOUND');
}

class RateLimitException extends AppException {
  RateLimitException([String message = 'Rate limit exceeded']) : super(message, 'RATE_LIMIT');
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;
  
  ValidationException(String message, [this.errors]) : super(message, 'VALIDATION_ERROR');
}

class FileException extends AppException {
  FileException([String message = 'File error']) : super(message, 'FILE_ERROR');
}

class PermissionException extends AppException {
  PermissionException([String message = 'Permission denied']) : super(message, 'PERMISSION_DENIED');
}