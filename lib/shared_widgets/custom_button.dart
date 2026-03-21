import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum ButtonType { primary, secondary, accent, outlined }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: type == ButtonType.outlined ? AppTheme.primary : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  icon,
                  size: 18,
                  color: type == ButtonType.outlined ? AppTheme.primary : Colors.white,
                ),
              ],
            ],
          );

    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: width ?? double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: child,
          ),
        );
      case ButtonType.secondary:
        return SizedBox(
          width: width ?? double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: AppTheme.primary,
            ),
            child: child,
          ),
        );
      case ButtonType.accent:
        return SizedBox(
          width: width ?? double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shadowColor: AppTheme.accent.withValues(alpha: 0.3),
              elevation: 4,
            ),
            child: child,
          ),
        );
      case ButtonType.outlined:
        return SizedBox(
          width: width ?? double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
    }
  }
}
