import builtins
import json as json_lib

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    content = f.read()
    data = json_lib.loads(content)

locales = ['te', 'ta', 'es', 'zh']

for code in locales:
    new_data = data.copy()
    new_data['@@locale'] = code
    with open(f'lib/l10n/app_{code}.arb', 'w', encoding='utf-8') as f:
        f.write(json_lib.dumps(new_data, ensure_ascii=False, indent=2))
