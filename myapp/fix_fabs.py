import os
import glob
import re

os.chdir('/Users/k0b0c22/Documents/GitHub/Antigravity/niyan/myapp')

# First update theme_provider.dart to have floatingActionButtonTheme for light theme
theme_file = 'lib/providers/theme_provider.dart'
with open(theme_file, 'r') as f:
    theme_content = f.read()

if 'floatingActionButtonTheme: const FloatingActionButtonThemeData' not in theme_content.split('static final ThemeData darkTheme')[0]:
    theme_content = theme_content.replace(
        'elevatedButtonTheme: ElevatedButtonThemeData(',
        'floatingActionButtonTheme: const FloatingActionButtonThemeData(\n      backgroundColor: primaryNavy,\n      foregroundColor: Colors.white,\n    ),\n    elevatedButtonTheme: ElevatedButtonThemeData('
    )
    with open(theme_file, 'w') as f:
        f.write(theme_content)

files = glob.glob('lib/screens/**/*.dart', recursive=True)
count = 0
for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We want to find FloatingActionButton... and then replace its backgroundColor if it's hardcoded.
    # A simple regex to find FloatingActionButton( ... ) and inside it replace backgroundColor
    
    def replacer(match):
        inner_content = match.group(2)
        # remove any backgroundColor: ...,
        new_inner = re.sub(r'backgroundColor:\s*[^,]+,\s*', '', inner_content)
        return match.group(1) + new_inner + match.group(3)

    # regex to match FloatingActionButton.something( ... )
    # we'll do a naive approach: look for FloatingActionButton
    new_content = re.sub(r'(FloatingActionButton(?:\.[a-zA-Z]+)?\()([^)]+)(\))', replacer, content, flags=re.DOTALL)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
        count += 1

print(f"Done! Updated {count} files.")
