import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/features/assistant/providers/chat_provider.dart';
import 'package:aspargo/features/assistant/widgets/chat_message_bubble.dart';
import 'package:aspargo/features/assistant/widgets/chat_input_field.dart';
import 'package:aspargo/features/assistant/widgets/suggestion_chips.dart';
import 'package:aspargo/features/assistant/widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Assistant'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.language),
                onSelected: (languageCode) {
                  provider.setLanguage(languageCode);
                },
                itemBuilder: (context) => provider.supportedLanguages
                    .map((lang) => PopupMenuItem<String>(
                          value: lang.code,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.name),
                              if (lang.code == provider.selectedLanguage)
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.messages.isEmpty) return const SizedBox.shrink();
              
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Conversation?'),
                      content: const Text(
                        'This will delete all messages in the current conversation.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            provider.clearConversation();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.messages.isEmpty) {
                    return _buildEmptyState(context, provider);
                  }
                  
                  // Auto-scroll when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: provider.messages.length + (provider.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.messages.length && provider.isTyping) {
                        return FadeIn(
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: TypingIndicator(),
                          ),
                        );
                      }
                      
                      final message = provider.messages[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: ChatMessageBubble(
                          message: message,
                          onSuggestionTap: provider.sendSuggestion,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Suggestions
            Consumer<ChatProvider>(
              builder: (context, provider, _) {
                if (provider.suggestions.isEmpty || provider.isTyping) {
                  return const SizedBox.shrink();
                }
                
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: SuggestionChips(
                    suggestions: provider.suggestions,
                    onTap: (suggestion) {
                      _textController.text = suggestion;
                      provider.sendMessage(suggestion);
                      _textController.clear();
                    },
                  ),
                );
              },
            ),
            
            // Input field
            ChatInputField(
              controller: _textController,
              onSend: (message) {
                context.read<ChatProvider>().sendMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, ChatProvider provider) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha((255 * 0.1).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Welcome to aspargo Assistant!',
              style: AppTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: Text(
              'I\'m here to help you with all your gardening and plant care questions. Ask me anything!',
              style: AppTheme.bodyLarge.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withAlpha((255 * 0.7).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try asking about:',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ...provider.suggestions.map((suggestion) => _buildSuggestionCard(
                  context,
                  suggestion,
                  () {
                    _textController.text = suggestion;
                    provider.sendMessage(suggestion);
                    _textController.clear();
                  },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionCard(BuildContext context, String suggestion, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion,
                  style: AppTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.textTheme.bodyMedium?.color?.withAlpha((255 * 0.5).round()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
