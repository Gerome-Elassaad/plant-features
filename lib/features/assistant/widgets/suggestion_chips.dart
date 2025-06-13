import 'package:flutter/material.dart';
import 'package:aspargo/core/theme/app_theme.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;
  
  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Suggestions',
              style: AppTheme.labelMedium.copyWith(
                color: theme.textTheme.labelMedium?.color?.withAlpha((255 * 0.7).round()),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: suggestions.map((suggestion) {
                return _SuggestionChip(
                  text: suggestion,
                  onTap: () => onTap(suggestion),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  
  const _SuggestionChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppTheme.primaryColor.withAlpha((255 * 0.1).round())
                  : AppTheme.primaryColor.withAlpha((255 * 0.08).round()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withAlpha((255 * 0.3).round()),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
