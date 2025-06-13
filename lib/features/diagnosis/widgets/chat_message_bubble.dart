import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:markdown_widget/markdown_widget.dart'; // Changed import
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/features/assistant/models/chat_model.dart'; // Assuming this model is okay here, or should be a diagnosis-specific one
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
                      color: AppTheme.primaryColor.withAlpha((255 * 0.1).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'aspargo Assistant', // Consider if this should be different for diagnosis
                    style: AppTheme.labelSmall.copyWith(
                      color: theme.textTheme.labelSmall?.color?.withAlpha((255 * 0.7).round()),
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
                const SnackBar(
                  content: Text('Message copied to clipboard'),
                  duration: Duration(seconds: 2),
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
                            ? theme.cardTheme.color ?? AppTheme.darkSurface
                            : Colors.grey.shade100,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 0.75, // MediaQuery.of(context).size.width cannot be const
                      ),
                      child: isUser
                          ? Text(
                              message.content,
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                            )
                          : MarkdownWidget(
                              data: message.content,
                              config: MarkdownConfig(
                                configs: [
                                  LinkConfig(
                                    onTap: (url) {
                                      if (onSuggestionTap != null) {
                                        onSuggestionTap!(url);
                                      }
                                    },
                                    style: TextStyle(
                                      color: isDark ? AppTheme.secondaryColor : AppTheme.primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  PConfig(
                                    textStyle: AppTheme.bodyMedium.copyWith(
                                      color: isDark ? theme.textTheme.bodyMedium?.color : Colors.black87,
                                    ),
                                  ),
                                  H1Config(
                                    style: AppTheme.headlineLarge.copyWith(
                                      color: isDark ? theme.textTheme.headlineLarge?.color : Colors.black87,
                                    ),
                                  ),
                                  H2Config(
                                    style: AppTheme.headlineMedium.copyWith(
                                      color: isDark ? theme.textTheme.headlineMedium?.color : Colors.black87,
                                    ),
                                  ),
                                  H3Config(
                                    style: AppTheme.headlineSmall.copyWith(
                                      color: isDark ? theme.textTheme.headlineSmall?.color : Colors.black87,
                                    ),
                                  ),
                                  CodeConfig(
                                    style: AppTheme.bodySmall.copyWith(
                                      fontFamily: 'monospace',
                                      backgroundColor: isDark ? Colors.grey.shade800.withAlpha((255 * 0.5).round()) : Colors.grey.shade200,
                                    ),
                                  ),
                                  PreConfig(
                                    textStyle: AppTheme.bodySmall.copyWith(fontFamily: 'monospace'),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 0.5)
                                    ),
                                    padding: const EdgeInsets.all(12.0),
                                  ),
                                  const BlockquoteConfig( 
                                     // Removed textStyle and decoration due to errors. Default styling will apply.
                                     padding: EdgeInsets.only(left: 12.0), // Padding is usually a safe bet
                                   ),
                                ],
                              ),
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
                color: theme.textTheme.labelSmall?.color?.withAlpha((255 * 0.5).round()),
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
        // ignore: deprecated_member_use
        color: AppTheme.errorColor.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withAlpha((255 * 0.3).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
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
