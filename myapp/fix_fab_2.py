import os
import glob

os.chdir('/Users/k0b0c22/Documents/GitHub/Antigravity/niyan/myapp')
files = glob.glob('lib/screens/**/*.dart', recursive=True)

for filepath in files:
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    changed = False
    in_fab = False
    paren_level = 0
    new_lines = []
    
    for line in lines:
        if 'FloatingActionButton' in line:
            in_fab = True
            
        if in_fab:
            paren_level += line.count('(') - line.count(')')
            
            if 'backgroundColor:' in line:
                if 'ThemeProvider.primaryNavy' in line or 'ThemeProvider.accentBlue' in line:
                    if 'brightness == Brightness.dark' not in line:
                        if 'ThemeProvider.primaryNavy' in line:
                            line = line.replace('ThemeProvider.primaryNavy', 'Theme.of(context).brightness == Brightness.dark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy')
                        elif 'ThemeProvider.accentBlue' in line:
                            line = line.replace('ThemeProvider.accentBlue', 'Theme.of(context).brightness == Brightness.dark ? ThemeProvider.accentTeal : ThemeProvider.accentBlue')
                        changed = True
            
            if paren_level <= 0 and '(' in line and ')' in line: # rough heuristic
                pass
            if paren_level <= 0 and not 'FloatingActionButton' in line:
                in_fab = False
                
        new_lines.append(line)
        
    if changed:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print(f"Updated {filepath}")
