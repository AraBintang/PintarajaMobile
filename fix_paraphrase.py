import re

with open(r'lib\features\paraphrase\paraphrase_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

with open(r'lib\features\writer\writer_screen.dart', 'r', encoding='utf-8') as f:
    writer_content = f.read()

# Extract _showTokenDialog from writer_screen
match = re.search(r'  void _showTokenDialog\(\) \{.*?(?=^  Widget _buildAppBar|\Z)', writer_content, re.MULTILINE | re.DOTALL)
if match:
    writer_dialog = match.group(0)
    
    # Replace in paraphrase
    new_content = re.sub(r'  void _showTokenDialog\(\) \{.*?(?=^  Widget _buildAppBar|\Z)', writer_dialog, content, flags=re.MULTILINE | re.DOTALL)
    
    with open(r'lib\features\paraphrase\paraphrase_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Could not find _showTokenDialog in writer_screen")
