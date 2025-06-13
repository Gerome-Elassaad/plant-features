class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // API Endpoints
  static const String diagnosis = '/diagnosis';
  static const String diagnosisModifiers = '/diagnosis/modifiers';
  static const String assistantChat = '/assistant/chat';
  static const String assistantStarters = '/assistant/starters';
  static const String assistantLanguages = '/assistant/languages';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // File upload limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Debug
  static const bool enableLogging = true; // when in production set false
}