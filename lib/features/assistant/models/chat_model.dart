class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isError;
  
  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isError = false,
  });
  
  Map<String, dynamic> toJson() => {
    'content': content,
    'role': role.toString().split('.').last,
  };
}

enum MessageRole { user, assistant }

class ChatResponse {
  final bool success;
  final ChatData data;
  
  ChatResponse({
    required this.success,
    required this.data,
  });
  
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      success: json['success'] ?? false,
      data: ChatData.fromJson(json['data'] ?? {}),
    );
  }
}

class ChatData {
  final String message;
  final ChatMetadata metadata;
  final List<String>? suggestions;
  
  ChatData({
    required this.message,
    required this.metadata,
    this.suggestions,
  });
  
  factory ChatData.fromJson(Map<String, dynamic> json) {
    return ChatData(
      message: json['message'] ?? '',
      metadata: ChatMetadata.fromJson(json['metadata'] ?? {}),
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
    );
  }
}

class ChatMetadata {
  final DateTime timestamp;
  final String language;
  final int? tokensUsed;
  
  ChatMetadata({
    required this.timestamp,
    required this.language,
    this.tokensUsed,
  });
  
  factory ChatMetadata.fromJson(Map<String, dynamic> json) {
    return ChatMetadata(
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      language: json['language'] ?? 'en',
      tokensUsed: json['tokens_used'],
    );
  }
}

class ConversationStarter {
  final String language;
  final List<String> starters;
  
  ConversationStarter({
    required this.language,
    required this.starters,
  });
  
  factory ConversationStarter.fromJson(Map<String, dynamic> json) {
    return ConversationStarter(
      language: json['language'] ?? 'en',
      starters: List<String>.from(json['starters'] ?? []),
    );
  }
}

class SupportedLanguage {
  final String code;
  final String name;
  final String native;
  
  SupportedLanguage({
    required this.code,
    required this.name,
    required this.native,
  });
  
  factory SupportedLanguage.fromJson(Map<String, dynamic> json) {
    return SupportedLanguage(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      native: json['native'] ?? '',
    );
  }
}