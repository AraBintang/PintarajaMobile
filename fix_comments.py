import glob
for file in glob.glob('lib/**/*.dart', recursive=True):
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'PINTARAJA A' in content or 'PINTARAJA ' in content:
        # replace any mojibake in the top comment
        content = content.replace('// PINTARAJA Ã¢â‚¬â€ ', '// PINTARAJA \u2014')
        content = content.replace('// PINTARAJA A,??', '// PINTARAJA \u2014')
        content = content.replace('// PINTARAJA ?"', '// PINTARAJA \u2014')
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
