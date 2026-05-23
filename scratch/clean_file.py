import os

file_path = r"c:\Users\darko\OneDrive\Desktop\Antigravity Projects\RPECG_investigation_app\files\lib\features\backoffice\presentation\widgets\report_schedule_dialog.dart"
output_path = r"c:\Users\darko\OneDrive\Desktop\Antigravity Projects\RPECG_investigation_app\files\lib\features\backoffice\presentation\widgets\report_schedule_dialog_cleaned.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

cleaned_lines = []

# Line 1 is the corrupted one. Let's see if there's anything useful at the end of it.
first_line = lines[0]
last_useful_index = first_line.rfind('import')
if last_useful_index != -1:
    # There might be valid imports at the end of the corrupted line
    potential_code = first_line[last_useful_index:]
    # But wait, the corruption might be interspersed. 
    # Let's just look for the last 'import' or 'class' or 'package'.
    
    # Actually, the user says the corruption is a massive amount of "../../".
    # Let's find the first occurrence of something that is NOT "../../" starting from the end.
    
    # For now, let's just skip line 1 and see what we have.
    pass

for line in lines[1:]:
    # Remove the "NN: " prefix if it exists
    parts = line.split(': ', 1)
    if len(parts) > 1 and parts[0].strip().isdigit():
        cleaned_lines.append(parts[1])
    else:
        cleaned_lines.append(line)

# Now we need to add the missing imports and class definition.
# Based on the context, we can guess them.
header = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/web_utils.dart';
import '../../../../domain/entities/report_config.dart';

class ReportScheduleDialog extends ConsumerStatefulWidget {
  const ReportScheduleDialog({super.key});

  @override
  ConsumerState<ReportScheduleDialog> createState() => _ReportScheduleDialogState();
}

class _ReportScheduleDialogState extends ConsumerState<ReportScheduleDialog> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedFrequency = 'Daily';
  String selectedFormat = 'PDF';
"""

full_content = header + "".join(cleaned_lines)

with open(output_path, 'w', encoding='utf-8') as f:
    f.write(full_content)

print(f"Cleaned file written to {output_path}")
