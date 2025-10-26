#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Remove ALL emoji characters from layer_paint_page.dart
This fixes the UTF-8 encoding error when joining collaboration
"""

import re

file_path = 'lib/all_code/page/layer_paint_page.dart'

# Read the file
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Emoji replacement mapping
emoji_replacements = {
    '🚀': '[ROCKET]',
    '�': '[ROCKET]',  # Corrupted rocket emoji
    '📊': '[CHART]',
    '🎯': '[TARGET]',
    '🔄': '[RELOAD]',
    '✅': '[OK]',
    '❌': '[ERROR]',
    '⏳': '[WAIT]',
    '⏭️': '[SKIP]',
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
}

# Replace each emoji
for emoji, replacement in emoji_replacements.items():
    content = content.replace(emoji, replacement)

# Also remove any remaining emoji using regex (Unicode emoji ranges)
# This catches any emoji we might have missed
emoji_pattern = re.compile(
    "["
    u"\U0001F600-\U0001F64F"  # emoticons
    u"\U0001F300-\U0001F5FF"  # symbols & pictographs
    u"\U0001F680-\U0001F6FF"  # transport & map symbols
    u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
    u"\U00002702-\U000027B0"
    u"\U000024C2-\U0001F251"
    u"\U0001F900-\U0001F9FF"  # Supplemental Symbols and Pictographs
    u"\U0001FA00-\U0001FA6F"  # Chess Symbols
    u"\U00002600-\U000026FF"  # Miscellaneous Symbols
    u"\U00002700-\U000027BF"  # Dingbats
    "]+", 
    flags=re.UNICODE
)

content = emoji_pattern.sub('[EMOJI]', content)

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ All emojis removed successfully!")
print(f"✓ File updated: {file_path}")
