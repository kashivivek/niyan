import re

files_with_const = [
    "lib/screens/admin/create_invoice_screen.dart",
    "lib/screens/invoice_detail_screen.dart",
    "lib/screens/login_screen.dart",
    "lib/screens/property_detail_screen.dart",
    "lib/screens/unit_detail_screen.dart"
]

for file in files_with_const:
    with open(file, 'r') as f:
        content = f.read()
    
    # Replace `const ` before widgets containing `Theme.of(context)`
    # This is tricky with regex, we'll just replace `const ` where `Theme.of(context)` is on the same line or next line.
    # It's better to just do `content = content.replace("const SizedBox", "SizedBox")` etc, but we don't know what it is.
    # Let's replace `const TextStyle` -> `TextStyle`
    # `const Icon` -> `Icon`
    content = content.replace("const TextStyle(", "TextStyle(")
    content = content.replace("const Icon(", "Icon(")
    content = content.replace("const BoxShadow(", "BoxShadow(")
    content = content.replace("const EdgeInsets", "EdgeInsets")
    content = content.replace("const Border(", "Border(")
    content = content.replace("const BorderSide(", "BorderSide(")
    
    with open(file, 'w') as f:
        f.write(content)

