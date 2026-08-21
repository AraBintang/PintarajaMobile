import sys

lines = open('lib/features/settings/settings_screen.dart', 'r', encoding='utf-8').readlines()

# find _showFileManagerModal end
start_idx = -1
for i, line in enumerate(lines):
    if 'class _FileManagerDialog extends StatefulWidget' in line:
        start_idx = i
        break

# find the end of _FileManagerDialogState
end_idx = -1
for i in range(start_idx, len(lines)):
    if '// ==========================================================' in lines[i] and 'REFERRAL' in lines[i+1]:
        end_idx = i - 1
        break

if start_idx != -1 and end_idx != -1:
    dialog_code = lines[start_idx:end_idx]
    
    # put the missing brace for _SettingsScreenState back
    lines.insert(start_idx, '}\n\n')
    
    # remove the dialog code from its current position
    del lines[start_idx+1 : end_idx+1]
    
    # append the dialog code to the end of the file
    lines.extend(dialog_code)
    
    with open('lib/features/settings/settings_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("Fixed!")
else:
    print("Could not find boundaries")
