import re

with open('lib/features/transcribe/transcribe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Instead of exact matching the messed up characters, let's use regex based on the structure.
content = re.sub(
    r"case 'upload':\s*return '[^']+';",
    "case 'upload':\n        return '📁';",
    content
)

content = re.sub(
    r"case 'youtube':\s*return '[^']+';",
    "case 'youtube':\n        return '🎬';",
    content
)

content = re.sub(
    r"case 'record':\s*return '[^']+';",
    "case 'record':\n        return '🎙️';",
    content
)

content = re.sub(
    r"default:\s*return '[^']+';\s*}\s*}",
    "default:\n        return '📄';\n    }\n  }",
    content
)

# Bullet point fix
content = re.sub(
    r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme\.textSecondary, fontSize: 11\)\)",
    "const Text('• ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11))",
    content
)

with open('lib/features/transcribe/transcribe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
