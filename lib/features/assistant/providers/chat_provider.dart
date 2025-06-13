import 'package:flutter/foundation.dart';
import 'package:arco/core/services/api_service.dart';
import 'package:arco/core/constants/api_constants.dart';
import 'package:arco/core/exceptions/app_exceptions.dart';
import 'package:arco/features/assistant/models/chat_model.dart';

enum ChatState { idle, loading, error }

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  
  ChatState _state = ChatState.idle;
  ChatState get state => _state;
  
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  
  List<String> _suggestions = [];
  List<String> get suggestions => _suggestions;
  
  String _selectedLanguage = 'en';
  String get selectedLanguage => _selectedLanguage;
  
  List<SupportedLanguage> _supportedLanguages = [];
  List<SupportedLanguage> get supportedLanguages => _supportedLanguages;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  bool _isTyping = false;
  bool get isTyping => _isTyping;
  
  ChatProvider() {
    _loadSupportedLanguages();
    _loadConversationStarters();
  }
  
  void _setState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }
  
  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    _loadConversationStarters();
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void clearConversation() {
    _messages.clear();
    _suggestions.clear();
    _errorMessage = null;
    _state = ChatState.idle;
    _loadConversationStarters();
    notifyListeners();
  }
  
  Future<void> _loadSupportedLanguages() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.assistantLanguages,
      );
      
      if (response['success'] == true) {
        _supportedLanguages = (response['data'] as List)
            .map((lang) => SupportedLanguage.fromJson(lang))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - use default language
    }
  }
  
  Future<void> _loadConversationStarters() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.assistantStarters,
        queryParameters: {'language': _selectedLanguage},
      );
      
      if (response['success'] == true && response['data'] != null) {
        final starter = ConversationStarter.fromJson(response['data']);
        _suggestions = starter.starters;
        notifyListeners();
      }
    } catch (e) {
      // Use default suggestions
      _suggestions = _getDefaultStarters();
      notifyListeners();
    }
  }
  
  List<String> _getDefaultStarters() {
    switch (_selectedLanguage) {
      case 'es':
        return [
          '¿Qué plantas son fáciles de cuidar?',
          '¿Cómo puedo mejorar mi jardín?',
          '¿Cuándo debo regar mis plantas?',
        ];
      case 'fr':
        return [
          'Quelles plantes sont faciles à entretenir?',
          'Comment améliorer mon jardin?',
          'Quand dois-je arroser mes plantes?',
        ];
      default:
        return [
          'What plants are easy to care for?',
          'How can I improve my garden?',
          'When should I water my plants?',
        ];
    }
  }
  
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _state == ChatState.loading) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    _suggestions.clear();
    _isTyping = true;
    _setState(ChatState.loading);
    
    try {
      // Prepare context (last 5 messages)
      final context = _messages
          .take(_messages.length - 1) // Exclude the message we just added
          .skip(_messages.length > 6 ? _messages.length - 6 : 0)
          .map((msg) => msg.toJson())
          .toList();
      
      // Send request
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.assistantChat,
        data: {
          'message': content,
          'context': context,
          'language': _selectedLanguage,
        },
      );
      
      // Parse response
      final chatResponse = ChatResponse.fromJson(response);
      
      if (chatResponse.success) {
        // Add assistant message
        final assistantMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: chatResponse.data.message,
          role: MessageRole.assistant,
          timestamp: chatResponse.data.metadata.timestamp,
        );
        
        _messages.add(assistantMessage);
        
        // Update suggestions
        if (chatResponse.data.suggestions != null) {
          _suggestions = chatResponse.data.suggestions!;
        }
        
        _setState(ChatState.idle);
      } else {
        throw AppException('Failed to get response');
      }
      
    } on NetworkException catch (e) {
      _handleError('Network error: ${e.message}');
    } on ServerException catch (e) {
      _handleError('Server error: ${e.message}');
    } on RateLimitException catch (e) {
      _handleError('Too many messages. Please wait a moment.');
    } catch (e) {
      _handleError('An unexpected error occurred');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
  
  void _handleError(String message) {
    _errorMessage = message;
    
    // Add error message to chat
    final errorMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isError: true,
    );
    
    _messages.add(errorMessage);
    _setState(ChatState.error);
  }
  
  void sendSuggestion(String suggestion) {
    sendMessage(suggestion);
  }
  
  bool get canSendMessage => _state != ChatState.loading;
}