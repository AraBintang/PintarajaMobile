import re

def fix_actions(path):
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
        
    match = re.search(search, content)
    if match:
        content = content.replace(match.group(0), "")
        # Replace the ), after title with ),\n + actions
        
        # for plagiarism:
        title_end_plag = r"""        title: Text\(
          'Cek Plagiarisme',
          style: TextStyle\(
              color: AppTheme.getTextColor\(context\),
              fontWeight: FontWeight.w700,
              fontSize: 17\),
        \),"""
        
        # for transcribe:
        title_end_trans = r"""        title: Text\(
          'Transcribe AI',
          style: TextStyle\(
              color: AppTheme.getTextColor\(context\),
              fontWeight: FontWeight.w700,
              fontSize: 17\),
        \),"""
        
        actions_str = """
        actions: [
          _TokenChip(
            balance: context.watch<AuthProvider>().tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 10),
        ],"""
        
        if 'Cek Plagiarisme' in content:
            content = content.replace(title_end_plag, title_end_plag + actions_str)
        if 'Transcribe AI' in content:
            content = content.replace(title_end_trans, title_end_trans + actions_str)
            
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {path}")

fix_actions(r'lib\features\plagiarism\plagiarism_screen.dart')
fix_actions(r'lib\features\transcribe\transcribe_screen.dart')
