import re

with open('lib/features/transcribe/transcribe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r"case 'upload':\s*return '[^']+';",
    "case 'upload':\n        return '\\U0001F4C1';",
    content
)

content = re.sub(
    r"case 'youtube':\s*return '[^']+';",
    "case 'youtube':\n        return '\\U0001F3AC';",
    content
)

content = re.sub(
    r"case 'record':\s*return '[^']+';",
    "case 'record':\n        return '\\U0001F399\\uFE0F';",
    content
)

content = re.sub(
    r"default:\s*return '[^']+';\s*}\s*}",
    "default:\n        return '\\U0001F4C4';\n    }\n  }",
    content
)

content = re.sub(
    r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme\.textSecondary, fontSize: 11\)\)",
    "const Text('\\u2022 ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11))",
    content
)

# Also fix the top comment
content = content.replace('// PINTARAJA Ã¢â‚¬â€  TRANSCRIBE SCREEN', '// PINTARAJA \u2014 TRANSCRIBE SCREEN')

with open('lib/features/transcribe/transcribe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
