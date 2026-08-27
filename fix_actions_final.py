import re

def insert_actions(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # ensure it's removed completely first
    search = r"""        actions: \[
          _TokenChip\(
            balance: context\.watch<AuthProvider>\(\)\.tokenBalance,
            onTap: _showTokenDialog,
          \),
          const SizedBox\(width: 10\),
        \],"""
    content = re.sub(search, "", content)
    
    # ensure it doesn't already have it
    if 'actions: [' not in content:
        replace = """        actions: [
          _TokenChip(
            balance: context.watch<AuthProvider>().tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 10),
        ],
        centerTitle: false,"""
        content = content.replace("        centerTitle: false,", replace)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Success for " + path)

insert_actions(r'lib\features\plagiarism\plagiarism_screen.dart')
insert_actions(r'lib\features\transcribe\transcribe_screen.dart')
