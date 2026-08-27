import re

def fix_it(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the wrongly placed actions block
    search = r"""        actions: \[
          _TokenChip\(
            balance: context\.watch<AuthProvider>\(\)\.tokenBalance,
            onTap: _showTokenDialog,
          \),
          const SizedBox\(width: 10\),
        \],"""
        
    # Remove it completely first
    content = re.sub(search, "", content)
    
    # Also remove it if it exists inside Text( but without regex
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_it(r'lib\features\plagiarism\plagiarism_screen.dart')
fix_it(r'lib\features\transcribe\transcribe_screen.dart')
