import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/features/assistant/providers/chat_provider.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  
  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _isComposing = false;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
  
  void _onTextChanged() {
    setState(() {
      _isComposing = widget.controller.text.trim().isNotEmpty;
    });
  }
  
  void _handleSubmit() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      widget.controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: provider.canSendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask about plant care...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        hintStyle: AppTheme.bodyMedium.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha((0.5 * 255).round()),
                        ),
                      ),
                      style: AppTheme.bodyMedium,
                      onSubmitted: provider.canSendMessage ? (_) => _handleSubmit() : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton(
                    onPressed: (_isComposing && provider.canSendMessage) 
                        ? _handleSubmit 
                        : null,
                    backgroundColor: (_isComposing && provider.canSendMessage)
                        ? AppTheme.primaryColor
                        : theme.disabledColor,
                    foregroundColor: Colors.white,
                    elevation: _isComposing ? 4 : 2,
                    mini: true,
                    child: provider.state == ChatState.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
