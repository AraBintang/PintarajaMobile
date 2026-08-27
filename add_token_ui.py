import re

# Add to plagiarism_screen.dart
with open(r'lib\features\plagiarism\plagiarism_screen.dart', 'r', encoding='utf-8') as f:
    plag = f.read()

with open(r'lib\features\writer\writer_screen.dart', 'r', encoding='utf-8') as f:
    writer_content = f.read()

# Extract _showTokenDialog and related imports from writer_screen if needed
match = re.search(r'  void _showTokenDialog\(\) \{.*?(?=^  Widget _buildAppBar|\Z)', writer_content, re.MULTILINE | re.DOTALL)
writer_dialog = match.group(0)

# Extract _TokenChip class
match_chip = re.search(r'class _TokenChip extends StatelessWidget \{.*?\n\}', writer_content, re.MULTILINE | re.DOTALL)
token_chip = match_chip.group(0)

# Add _showTokenDialog into plagiarism_screen.dart State class
if 'void _showTokenDialog()' not in plag:
    plag = re.sub(r'(  @override\n  Widget build\(BuildContext context\))', writer_dialog + r'\1', plag)

# Add tokenBalance into AppBar of plagiarism_screen.dart
appbar_search = r"(title: Text\(\n\s*'Cek Plagiarisme',\n\s*style: TextStyle\(\n\s*color: AppTheme\.getTextColor\(context\),\n\s*fontWeight: FontWeight\.w700,\n\s*\),\n\s*\),)"
appbar_replace = appbar_search + r"""
        actions: [
          _TokenChip(
            balance: context.watch<AuthProvider>().tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 10),
        ],"""
if 'actions: [' not in plag:
    plag = re.sub(appbar_search, appbar_replace, plag)

# Add _TokenChip class at the end of the file
if 'class _TokenChip extends' not in plag:
    plag += '\n\n' + token_chip

with open(r'lib\features\plagiarism\plagiarism_screen.dart', 'w', encoding='utf-8') as f:
    f.write(plag)

# Now do the same for transcribe_screen.dart
with open(r'lib\features\transcribe\transcribe_screen.dart', 'r', encoding='utf-8') as f:
    transcribe = f.read()

if 'void _showTokenDialog()' not in transcribe:
    transcribe = re.sub(r'(  @override\n  Widget build\(BuildContext context\))', writer_dialog + r'\1', transcribe)

appbar_search_tr = r"(title: Text\(\n\s*'Transcribe AI',\n\s*style: TextStyle\(\n\s*color: AppTheme\.getTextColor\(context\),\n\s*fontWeight: FontWeight\.w700,\n\s*\),\n\s*\),)"
appbar_replace_tr = appbar_search_tr + r"""
        actions: [
          _TokenChip(
            balance: context.watch<AuthProvider>().tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 10),
        ],"""
if 'actions: [' not in transcribe:
    transcribe = re.sub(appbar_search_tr, appbar_replace_tr, transcribe)

if 'class _TokenChip extends' not in transcribe:
    transcribe += '\n\n' + token_chip

with open(r'lib\features\transcribe\transcribe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(transcribe)

print("Added token UI to plagiarism and transcribe")
