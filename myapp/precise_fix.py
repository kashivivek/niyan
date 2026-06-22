import re

fixes = {
    'lib/screens/community/notice_board_screen.dart': [
        ('decoration: const BoxDecoration(\n              color: Theme.of(context).cardColor,', 
         'decoration: BoxDecoration(\n              color: Theme.of(context).cardColor,'),
    ],
    'lib/screens/admin/helpdesk_screen.dart': [
        ('decoration: const BoxDecoration(\n        color: Theme.of(context).cardColor,', 
         'decoration: BoxDecoration(\n        color: Theme.of(context).cardColor,'),
    ],
    'lib/screens/security/gate_dashboard_screen.dart': [
        ('decoration: const BoxDecoration(\n          color: Theme.of(context).cardColor,',
         'decoration: BoxDecoration(\n          color: Theme.of(context).cardColor,'),
        ('const Positioned(\n                      bottom: 80,\n                      left: 0,\n                      right: 0,\n                      child: Center(\n                        child: Text(\n                          \'Scan Resident or Visitor QR\',\n                          style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),',
         'Positioned(\n                      bottom: 80,\n                      left: 0,\n                      right: 0,\n                      child: Center(\n                        child: Text(\n                          \'Scan Resident or Visitor QR\',\n                          style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),'),
    ],
    'lib/screens/security/visitor_pre_approve_screen.dart': [
        ('const QrEyeStyle(\n                              eyeShape: QrEyeShape.square,\n                              color: Theme.of(context).colorScheme.primary,\n                            )',
         'QrEyeStyle(\n                              eyeShape: QrEyeShape.square,\n                              color: Theme.of(context).colorScheme.primary,\n                            )'),
        ('const QrDataModuleStyle(\n                              dataModuleShape: QrDataModuleShape.square,\n                              color: Theme.of(context).colorScheme.primary,\n                            )',
         'QrDataModuleStyle(\n                              dataModuleShape: QrDataModuleShape.square,\n                              color: Theme.of(context).colorScheme.primary,\n                            )'),
    ],
    'lib/screens/main_navigation_screen.dart': [
        ('const Column(\n            mainAxisAlignment: MainAxisAlignment.center,\n            children: [\n              CircularProgressIndicator(color: ThemeProvider.accentTeal),\n              SizedBox(height: 16),\n              Text(\'Switching to Society Mode...\', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),',
         'Column(\n            mainAxisAlignment: MainAxisAlignment.center,\n            children: [\n              CircularProgressIndicator(color: ThemeProvider.accentTeal),\n              SizedBox(height: 16),\n              Text(\'Switching to Society Mode...\', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),'),
    ],
    'lib/screens/tenant_detail_screen.dart': [
        ('Colors.white?.color', 'Colors.white'),
    ],
    'lib/screens/unit_detail_screen.dart': [
        ('Colors.white?.color', 'Colors.white'),
    ],
}

for filepath, file_fixes in fixes.items():
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        for old, new in file_fixes:
            if old in content:
                content = content.replace(old, new, 1)
                print(f'Fixed {filepath}: {old[:50]}')
            else:
                print(f'NOT FOUND in {filepath}: {old[:50]}')
        with open(filepath, 'w') as f:
            f.write(content)
    except FileNotFoundError:
        print(f'File not found: {filepath}')

