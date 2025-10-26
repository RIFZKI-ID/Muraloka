#!/usr/bin/env python3
"""
Fix all emoji bytes in layer_paint_page.dart
"""

# Read as binary
with open('lib/all_code/page/layer_paint_page.dart', 'rb') as f:
    data = f.read()

# Emoji byte replacements
replacements = {
    b'\xef\xbf\xbd': b'[ROCKET]',  # � (replacement character)
    b'\xf0\x9f\x9a\x80': b'[ROCKET]',  # 🚀
    b'\xf0\x9f\x93\x8a': b'[CHART]',   # 📊
    b'\xf0\x9f\x8e\xaf': b'[TARGET]',  # 🎯
    b'\xf0\x9f\x94\x84': b'[RELOAD]',  # 🔄
    b'\xe2\x9c\x85': b'[OK]',          # ✅
    b'\xe2\x9d\x8c': b'[ERROR]',       # ❌
    b'\xe2\x8f\xb3': b'[WAIT]',        # ⏳
    b'\xe2\x8f\xad\xef\xb8\x8f': b'[SKIP]',  # ⏭️
    b'\xf0\x9f\x91\xa5': b'[USERS]',   # 👥
    b'\xf0\x9f\x93\xa5': b'[LOAD]',    # 📥
    b'\xf0\x9f\x8e\xa8': b'[RENDER]',  # 🎨
    b'\xf0\x9f\x93\xa6': b'[PACK]',    # 📦
    b'\xf0\x9f\x92\xbe': b'[SAVE]',    # 💾
    b'\xf0\x9f\x93\xb8': b'[CAMERA]',  # 📸
    b'\xe2\x9a\xa0\xef\xb8\x8f': b'[WARN]',  # ⚠️
    b'\xf0\x9f\x93\x9d': b'[NOTE]',    # 📝
    b'\xe2\x84\xb9\xef\xb8\x8f': b'[INFO]',  # ℹ️
    b'\xf0\x9f\x93\x81': b'[FOLDER]',  # 📁
    b'\xf0\x9f\x93\x82': b'[PICKER]',  # 📂
}

# Apply replacements
for emoji_bytes, replacement in replacements.items():
    count = data.count(emoji_bytes)
    if count > 0:
        print(f"Replacing {emoji_bytes} ({count} occurrences)")
        data = data.replace(emoji_bytes, replacement)

# Write back
with open('lib/all_code/page/layer_paint_page.dart', 'wb') as f:
    f.write(data)

print("\n✓ All emoji bytes replaced!")
