import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/features/assistant/models/chat_model.dart';
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
        bottom: 16,
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
                    'aspargo Assistant',
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
                : _buildMessageBubble(context, isUser, isDark),
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

  Widget _buildMessageBubble(BuildContext context, bool isUser, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.primaryColor
            : isDark
                ? theme.cardTheme.color
                : Colors.grey.shade100,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
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
                  // StrongMdConfig, EmMdConfig, LiMdConfig removed for now due to persistent errors
                  // BlockquoteConfig styling also simplified/removed if parameters were causing issues
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
    );
  }

  Widget _buildErrorBubble(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
