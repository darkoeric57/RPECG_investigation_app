import 'package:flutter/material.dart';

class MultiSelectField extends StatelessWidget {
  final String label;
  final List<String> selectedItems;
  final List<String> options;
  final Function(List<String>) onSelectionChanged;

  const MultiSelectField({
    super.key,
    required this.label,
    required this.selectedItems,
    required this.options,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSelectionDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: selectedItems.isEmpty
                      ? Text('Select $label...', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: selectedItems.map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    final newList = List<String>.from(selectedItems)..remove(item);
                                    onSelectionChanged(newList);
                                  },
                                  child: const Icon(Icons.close, size: 12, color: Color(0xFF1E3A8A)),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionDialog(BuildContext context) {
    List<String> localSelectedItems = List<String>.from(selectedItems);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text('Select $label', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 18)),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: ListBody(
                    children: options.map((option) {
                      final isSelected = localSelectedItems.contains(option);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                        activeColor: const Color(0xFF1E3A8A),
                        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked!) {
                              if (!localSelectedItems.contains(option)) localSelectedItems.add(option);
                            } else {
                              localSelectedItems.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    onSelectionChanged(localSelectedItems);
                    Navigator.pop(context);
                  },
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
