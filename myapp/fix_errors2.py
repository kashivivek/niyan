import subprocess
out = subprocess.check_output(['flutter', 'analyze'], text=True)
errors = []
for line in out.splitlines():
    if "error •" in line and "lib/screens" in line:
        errors.append(line.strip())
print("\n".join(errors))
