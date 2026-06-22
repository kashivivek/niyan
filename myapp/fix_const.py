import re

files_to_fix = [
    'lib/screens/login_screen.dart',
    'lib/screens/notification_settings_screen.dart',
    'lib/screens/property_list_screen.dart',
    'lib/screens/settings_screen.dart',
]

for filepath in files_to_fix:
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
        new_content = re.sub(r'const\s+(EdgeInsets|BorderSide|SizedBox|Text|Icon|TextStyle|BoxDecoration|BorderRadius|BoxShadow)', r'\1', content)
        new_content = re.sub(r'const\s+(Expanded|Padding|Column|Row|Container)', r'\1', new_content)
        
        # fix specific lines based on errors
        
        with open(filepath, 'w') as f:
            f.write(new_content)
    except FileNotFoundError:
        pass

