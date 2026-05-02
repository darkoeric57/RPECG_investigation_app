import json

log_file = r'C:\Users\darko\.gemini\antigravity\brain\719d473a-2dac-41a4-87d1-c2bd0cb5d151\.system_generated\logs\overview.txt'

with open(log_file, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('type') == 'PLANNER_RESPONSE':
                for tool in data.get('tool_calls', []):
                    if 'data_management_page.dart' in str(tool):
                        print(tool.get('name'))
                        if tool.get('name') in ['replace_file_content', 'multi_replace_file_content']:
                            # save the chunks to see what was replaced
                            with open('chunks_replaced.json', 'w') as out:
                                json.dump(tool, out, indent=2)
                            print('Saved chunks!')
        except Exception as e:
            pass
