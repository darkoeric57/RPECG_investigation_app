import json

log_file = r'C:\Users\darko\.gemini\antigravity\brain\719d473a-2dac-41a4-87d1-c2bd0cb5d151\.system_generated\logs\overview.txt'

with open(log_file, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('type') == 'PLANNER_RESPONSE':
                for tool in data.get('tool_calls', []):
                    if tool.get('name') in ['replace_file_content', 'multi_replace_file_content']:
                        if 'data_management_page.dart' in tool.get('args', {}).get('TargetFile', ''):
                            with open('original_target_content.txt', 'w', encoding='utf-8') as out:
                                out.write(tool['args']['TargetContent'])
                            with open('replacement_content.txt', 'w', encoding='utf-8') as out:
                                out.write(tool['args']['ReplacementContent'])
                            print('Extracted fully.')
        except Exception as e:
            pass
