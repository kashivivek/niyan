import os
import re

files_to_fix = [
    'lib/widgets/vibrant_dashboard_tile.dart',
    'lib/screens/standalone_dashboard_screen.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/property_list_screen.dart',
    'lib/screens/tenant_list_screen.dart',
    'lib/screens/resident/resident_dashboard_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/admin/admin_dashboard_screen.dart'
]

replacements = [
    (r'color:\s*Colors\.white\s*,', r'color: Theme.of(context).cardColor,'),
    (r'color:\s*Colors\.grey\.shade50\s*,', r'color: Theme.of(context).scaffoldBackgroundColor,'),
    (r'color:\s*Colors\.grey\.shade100\s*,', r'color: Theme.of(context).dividerColor,'),
    (r'color:\s*Colors\.grey\.shade200\s*,', r'color: Theme.of(context).dividerColor,'),
    (r'color:\s*ThemeProvider\.primaryNavy\s*,', r'color: Theme.of(context).colorScheme.primary,'),
    (r'color:\s*ThemeProvider\.primaryNavy\s*\)', r'color: Theme.of(context).colorScheme.primary)'),
    (r'color:\s*Colors\.black87\s*,', r'color: Theme.of(context).textTheme.bodyLarge?.color,'),
    (r'color:\s*Colors\.black54\s*,', r'color: Theme.of(context).textTheme.bodyMedium?.color,'),
    (r'color:\s*Colors\.black\s*,', r'color: Theme.of(context).colorScheme.primary,'),
    (r'color:\s*Colors\.grey\.shade500\s*,', r'color: Theme.of(context).textTheme.bodyMedium?.color,'),
    (r'color:\s*Colors\.grey\.shade600\s*,', r'color: Theme.of(context).textTheme.bodyMedium?.color,'),
]

for filepath in files_to_fix:
    with open(filepath, 'r') as f:
        content = f.read()
    
    new_content = content
    for pattern, replacement in replacements:
        new_content = re.sub(pattern, replacement, new_content)
        
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

