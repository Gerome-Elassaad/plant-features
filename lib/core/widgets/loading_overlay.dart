import 'package:flutter/material.dart';
import 'package:aspargo/core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  final double? progress;
  final bool isVisible;
  final Widget? child;
  
  const LoadingOverlay({
    super.key,
    required this.message,
    this.progress,
    this.isVisible = true,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return child ?? const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        if (child != null) child!,
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Center(
              child: _buildLoadingCard(context),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress != null)
            _buildProgressIndicator()
          else
            _buildSpinner(),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${(progress! * 100).toStringAsFixed(0)}%',
          style: AppTheme.headlineMedium.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpinner() {
    return const SizedBox(
      width: 60,
      height: 60,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.primaryColor,
        ),
      ),
    );
  }
}

// Convenience method for showing loading overlay as a dialog
class LoadingDialog {
  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // ignore: deprecated_member_use
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: LoadingOverlay(
          message: message,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
  
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}