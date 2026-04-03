import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  final bool isLoading;
  final int? maxLines;
  final bool autoFocus;
  final TextCapitalization textCapitalization;
  final bool showLabel;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.initialValue,
    this.isLoading = false,
    this.maxLines = 1,
    this.autoFocus = false,
    this.textCapitalization = TextCapitalization.words,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                letterSpacing: 1.2,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          autofocus: autoFocus,
          validator: validator,
          onChanged: (val) {
            onChanged?.call(val);
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
            height: 1.2, // Force consistent line height
          ),
          decoration: InputDecoration(
            isDense: true, // Use isDense to have more control over padding
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.textLight.withValues(alpha: 0.6), 
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textLight, size: 20) : null,
            suffixIcon: isLoading 
                ? const UnconstrainedBox(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (suffixIcon != null
                    ? IconButton(
                        icon: Icon(suffixIcon, color: AppTheme.textLight, size: 20),
                        onPressed: onSuffixTap,
                      )
                    : null),
          ),
        ),
      ],
    );
  }
}
