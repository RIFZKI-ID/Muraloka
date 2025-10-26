#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fix UTF-8 encoding errors by replacing specific problematic lines
"""

import io

file_path = 'lib/all_code/page/layer_paint_page.dart'

# Read file dengan handling untuk bad UTF-8
with io.open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

# Track changes
changes = 0

# Process each line
for i in range(len(lines)):
    original = lines[i]
    
    # Replace any line with "Auto-saving"
    if 'Auto-saving' in lines[i]:
        lines[i] = lines[i].replace('Auto-saving', 'Saving')
        # Remove any emoji before "Auto-saving" or "Saving"
        lines[i] = lines[i].replace('� ', '')
        lines[i] = lines[i].replace('🚀 ', '')
        lines[i] = lines[i].replace("print('", "print('[AUTO-SAVE] ")
        if original != lines[i]:
            changes += 1
            print(f"Line {i+1}: Fixed Auto-saving")
    
    # Replace "Real-time update"
    if 'Real-time update' in lines[i]:
        lines[i] = lines[i].replace('� Real-time', '[COLLAB] Real-time')
        lines[i] = lines[i].replace('🚀 Real-time', '[COLLAB] Real-time')
        if original != lines[i]:
            changes += 1
            print(f"Line {i+1}: Fixed Real-time update")
    
    # Replace other common emojis
    emoji_map = {
        '⏭️': '[SKIP]',
        '📊': '[CHART]',
        '🎯': '[TARGET]',
        '🔄': '[RELOAD]',
        '✅': '[OK]',
        '❌': '[ERROR]',
        '⏳': '[WAIT]',
        '👥': '[USERS]',
        '📥': '[LOAD]',
        '🎨': '[RENDER]',
        '📦': '[PACK]',
        '💾': '[SAVE]',
        '📸': '[CAMERA]',
        '⚠️': '[WARN]',
        '📝': '[NOTE]',
        'ℹ️': '[INFO]',
        '📁': '[FOLDER]',
        '📂': '[PICKER]',
        '�': '',  # Remove replacement character
    }
    
    for emoji, replacement in emoji_map.items():
        if emoji in lines[i]:
            lines[i] = lines[i].replace(emoji + ' ', replacement + ' ')
            lines[i] = lines[i].replace(emoji, replacement)
            if original != lines[i]:
                changes += 1

# Write back dengan UTF-8 yang benar
with io.open(file_path, 'w', encoding='utf-8', newline='\n') as f:
    f.writelines(lines)

print(f"\n✓ Fixed {changes} lines!")
print(f"✓ File updated: {file_path}")
