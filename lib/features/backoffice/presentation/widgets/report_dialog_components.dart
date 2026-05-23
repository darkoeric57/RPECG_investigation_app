import 'package:flutter/material.dart';

/// A library of reusable UI components for the Billing Intelligence report configuration dialogs.
/// These components ensure a consistent design language and premium feel across the backoffice suite.


/// A custom selectable list item used for frequency or type selection.
/// Features hover effects and a refined "active" state animation.
class SelectableTab extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SelectableTab> createState() => _SelectableTabState();
}

class _SelectableTabState extends State<SelectableTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.white 
                : (_isHovered ? Colors.white.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isSelected 
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] 
                : null,
            border: Border.all(color: widget.isSelected ? const Color(0xFFE2E8F0) : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized button for file format selection (CSV, PDF, EXCEL).
/// Uses a high-contrast style when selected to indicate the primary output target.
class FormatButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FormatButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<FormatButton> createState() => _FormatButtonState();
}

class _FormatButtonState extends State<FormatButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? const Color(0xFF1E3A8A) 
                : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected 
                  ? const Color(0xFF1E3A8A) 
                  : (_isHovered ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
            boxShadow: widget.isSelected 
                ? [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 6))] 
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : const Color(0xFF1E293B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A premium toggle switch for "Restricted Mode" or other binary administrative settings.
/// Displays an icon and descriptive labels that change based on state.
class RestrictedToggle extends StatelessWidget {
  final bool isRestricted;
  final ValueChanged<bool> onChanged;

  const RestrictedToggle({
    super.key,
    required this.isRestricted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isRestricted 
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.05) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRestricted 
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.2) 
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: isRestricted ? [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isRestricted 
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) 
                  : const Color(0xFF64748B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRestricted ? Icons.admin_panel_settings_rounded : Icons.no_encryption_gmailerrorred_rounded,
              color: isRestricted ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RESTRICTED MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isRestricted ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                isRestricted ? 'Admin lock enabled' : 'Manual overrides active',
                style: TextStyle(
                  fontSize: 9,
                  color: isRestricted ? const Color(0xFF1E3A8A).withValues(alpha: 0.7) : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          SizedBox(
            height: 24,
            width: 44,
            child: Switch(
              value: isRestricted,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF10B981),
              activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.2),
              inactiveThumbColor: const Color(0xFF94A3B8),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isRestricted ? const Color(0xFF10B981) : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            child: Text(isRestricted ? 'ENABLED' : 'DISABLED'),
          ),
        ],
      ),
    );
  }
}

/// A standardized wrapper for a dialog section, featuring a numbered label.
/// Helps organize complex configuration forms into readable, logical steps.
class ReportSection extends StatelessWidget {
  final String number;
  final String label;
  final Widget child;

  const ReportSection({
    super.key,
    required this.number,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// A themed input field specifically designed for date selection.
/// Includes an integrated icon and consistent border styling.
class DatePickerField extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const DatePickerField({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple key-value row used for displaying summary data in report previews.
/// Ensures alignment and consistent typography for data labels and values.
class PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const PreviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
