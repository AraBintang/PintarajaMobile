with open('lib/features/transcribe/transcribe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('AppTheme.accentPurple', 'AppTheme.primary')

with open('lib/features/transcribe/transcribe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done. Replaced all accentPurple with primary.")
