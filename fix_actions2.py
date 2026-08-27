import re

def insert_actions(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'actions: [' in content:
        print(f"Already has actions: {path}")
        return

    # Find the title: Text(...) block in AppBar
    title_start = content.find('title: Text(')
    if title_start != -1:
        # Find the comma after fontSize: 17)
        font_size_idx = content.find('fontSize: 17)', title_start)
        if font_size_idx != -1:
            insert_idx = content.find(',', font_size_idx) + 1
            
            actions_str = """
        actions: [
          _TokenChip(
            balance: context.watch<AuthProvider>().tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 10),
        ],"""
            
            content = content[:insert_idx] + actions_str + content[insert_idx:]
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Added actions to {path}")

insert_actions(r'lib\features\plagiarism\plagiarism_screen.dart')
insert_actions(r'lib\features\transcribe\transcribe_screen.dart')
