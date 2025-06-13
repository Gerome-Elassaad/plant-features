import 'package:flutter/material.dart';
import 'package:aspargo/core/theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 48, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Assistant avatar
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.cardTheme.color
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(200),
                const SizedBox(width: 4),
                _buildDot(400),
                const SizedBox(width: 8),
                Text(
                  'aspargo is typing...',
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha((0.6 * 255).round()),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _getScaleForDot(delay),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha((0.7 * 255).round()),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  double _getScaleForDot(int delay) {
    final progress = (_animationController.value * 1000 - delay) / 200;
    if (progress < 0 || progress > 1) return 0.5;
    return 0.5 + (_animation.value * 0.5);
  }
}
