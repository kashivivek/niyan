import re
import subprocess

def run_analyze():
    try:
        out = subprocess.check_output(['flutter', 'analyze'], text=True)
        return out
    except subprocess.CalledProcessError as e:
        return e.output

def fix_errors():
    for _ in range(2):
        out = run_analyze()
        lines = [l.strip() for l in out.splitlines() if 'error •' in l]
        if not lines:
            print("No more errors!")
            break
            
        print(f"Found {len(lines)} errors")
        
        for line in lines:
            parts = line.split('•')
            if len(parts) >= 3:
                error_type = parts[3].strip()
                file_info = parts[2].strip().split(':')
                if len(file_info) >= 2:
                    filepath = file_info[0]
                    line_num = int(file_info[1])
                    
                    try:
                        with open(filepath, 'r') as f:
                            content = f.readlines()
                        
                        target_line = content[line_num - 1]
                        
                        if error_type == 'const_eval_method_invocation':
                            # Remove 'const' from the line
                            content[line_num - 1] = re.sub(r'\bconst\b\s*', '', target_line)
                        elif error_type == 'undefined_getter' and 'color' in line:
                            content[line_num - 1] = target_line.replace('.color.color', '.color')

                        with open(filepath, 'w') as f:
                            f.writelines(content)
                    except Exception as e:
                        print(f"Error fixing {filepath}:{line_num}: {e}")

fix_errors()
