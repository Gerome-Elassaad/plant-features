class ApiConstants {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  static const String _developmentBaseUrl = 'http://localhost:3000/api';
  static const String _productionBaseUrl = 'https://backend-domain.com/api';
  
  static String get baseUrl => isProduction ? _productionBaseUrl : _developmentBaseUrl;

  static bool get enableLogging => !isProduction; // Added for logging
  
  static const String diagnosisEndpoint = '/diagnosis/analyze';
  static const String chatEndpoint = '/assistant/chat';
  static const String languagesEndpoint = '/assistant/languages';
  static const String startersEndpoint = '/assistant/starters';
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
  
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  static const Duration cacheMaxAge = Duration(hours: 1);
  static const Duration cacheStaleAge = Duration(hours: 24);

  static String get diagnosis => diagnosisEndpoint;
  static String get assistantChat => chatEndpoint;
  static String get assistantLanguages => languagesEndpoint;
  static String get assistantStarters => startersEndpoint;
}
