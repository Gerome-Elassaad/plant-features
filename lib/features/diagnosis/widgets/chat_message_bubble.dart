import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:arco/core/theme/app_theme.dart';
import 'package:arco/features/assistant/models/chat_model.dart';
import 'package:intl/intl.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onSuggestionTap;
  
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser && !message.isError)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.eco,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Arco Assistant',
                    style: AppTheme.labelSmall.copyWith(
                      color: theme.textTheme.labelSmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          
          GestureDetector(
            onLongPress: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Message copied to clipboard'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: message.isError
                ? _buildErrorBubble(context)
                : ChatBubble(
                    clipper: ChatBubbleClipper5(
                      type: isUser ? BubbleType.sendBubble : BubbleType.receiverBubble,
                    ),
                    alignment: isUser ? Alignment.topRight : Alignment.topLeft,
                    margin: const EdgeInsets.only(top: 4),
                    backGroundColor: isUser
                        ? AppTheme.primaryColor
                        : isDark
                            ? theme.cardTheme.color
                            : Colors.grey.shade100,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: isUser
                          ? Text(
                              message.content,
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                            )
                          : MarkdownBody(
                              data: message.content,
                              styleSheet: MarkdownStyleSheet(
                                p: AppTheme.bodyMedium.copyWith(
                                  color: isDark ? theme.textTheme.bodyMedium?.color : Colors.black87,
                                ),
                                h1: AppTheme.headlineLarge.copyWith(
                                  color: isDark ? theme.textTheme.headlineLarge?.color : Colors.black87,
                                ),
                                h2: AppTheme.headlineMedium.copyWith(
                                  color: isDark ? theme.textTheme.headlineMedium?.color : Colors.black87,
                                ),
                                h3: AppTheme.headlineSmall.copyWith(
                                  color: isDark ? theme.textTheme.headlineSmall?.color : Colors.black87,
                                ),
                                strong: const TextStyle(fontWeight: FontWeight.bold),
                                em: const TextStyle(fontStyle: FontStyle.italic),
                                code: AppTheme.bodySmall.copyWith(
                                  fontFamily: 'monospace',
                                  backgroundColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                blockquote: AppTheme.bodyMedium.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                                listBullet: AppTheme.bodyMedium.copyWith(
                                  color: isDark ? theme.textTheme.bodyMedium?.color : Colors.black87,
                                ),
                              ),
                              onTapLink: (text, href, title) {
                                if (href != null && onSuggestionTap != null) {
                                  onSuggestionTap!(href);
                                }
                              },
                            ),
                    ),
                  ),
          ),
          
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 12,
              right: isUser ? 12 : 0,
              top: 4,
            ),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: AppTheme.labelSmall.copyWith(
                color: theme.textTheme.labelSmall?.color?.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorBubble(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message.content,
              style: AppTheme.bodyMedium.copyWith(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}