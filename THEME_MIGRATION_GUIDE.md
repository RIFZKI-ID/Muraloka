# Theme Migration Guide - Dark/Light Mode

## Overview
Panduan ini menjelaskan cara menerapkan tema dark/light mode konsisten di semua halaman menggunakan `AppColors` dari `constant.dart`.

## AppColors Reference

### Light Mode Colors
```dart
AppColors.lightBackground = Color(0xFFF5F7FA); // Light gray-blue background
AppColors.lightSurface = Color(0xFFFFFFFF);    // White surface
AppColors.lightSecondary = Color(0xFF5B9BD5);  // Lighter blue
AppColors.lightAccent = Color(0xFF4A90E2);     // Accent blue
```

### Dark Mode Colors
```dart
AppColors.darkBackground = Color(0xFF1A1D2E);  // Dark blue-gray
AppColors.darkSurface = Color(0xFF2C3E50);     // Dark surface
AppColors.darkSecondary = Color(0xFF34495E);   // Secondary dark
AppColors.darkAccent = Color(0xFF5DADE2);      // Bright accent for dark mode
```

### Primary Color
```dart
AppColors.primary1 = Color(0xFF2196F3);        // Material Blue
```

## Implementation Pattern

### Step 1: Import AppColors
```dart
import '../../constant/constant.dart';
```

### Step 2: Add Theme Helper Function
Add this at the beginning of your build method or as a widget method:

```dart
Widget build(BuildContext context) {
  // Theme-aware colors
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final primaryColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
  final textColor = isDark ? Colors.white : Colors.black87;
  final subtitleColor = isDark ? Colors.white70 : Colors.black54;
  final borderColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  
  return Scaffold(
    backgroundColor: backgroundColor,
    // ... rest of code
  );
}
```

### Step 3: Replace Hardcoded Colors

#### Before (Hardcoded):
```dart
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),
  ),
)
```

#### After (Theme-aware):
```dart
Container(
  color: surfaceColor,
  child: Text(
    'Hello',
    style: TextStyle(color: textColor),
  ),
)
```

## Common Patterns

### 1. Scaffold Background
```dart
Scaffold(
  backgroundColor: backgroundColor,
  ...
)
```

### 2. Card/Container Surface
```dart
Container(
  decoration: BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.2),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  ...
)
```

### 3. AppBar
```dart
AppBar(
  backgroundColor: surfaceColor,
  elevation: isDark ? 0 : 1,
  iconTheme: IconThemeData(color: textColor),
  title: Text(
    'Title',
    style: TextStyle(color: textColor),
  ),
)
```

### 4. Buttons
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
  ),
  onPressed: () {},
  child: Text('Button'),
)
```

### 5. Text Styles
```dart
// Primary text
Text(
  'Title',
  style: TextStyle(
    color: textColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
)

// Secondary text
Text(
  'Subtitle',
  style: TextStyle(
    color: subtitleColor,
    fontSize: 14,
  ),
)
```

### 6. Borders and Dividers
```dart
Divider(
  color: isDark ? Colors.white24 : Colors.black12,
  height: 1,
)

Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: borderColor.withOpacity(0.3),
      width: 1,
    ),
  ),
)
```

### 7. Icons
```dart
Icon(
  Icons.home,
  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
  size: 24,
)
```

### 8. Gradient Backgrounds
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        primaryColor,
        primaryColor.withOpacity(0.8),
      ],
    ),
  ),
)
```

## Files to Update

### Priority 1 (High Usage)
- [x] `lib/constant/constant.dart` - Fixed primary1 color
- [ ] `lib/presentation/pages/qris_payment_page.dart` - In progress
- [ ] `lib/all_code/page/marketplace_page.dart`
- [ ] `lib/all_code/page/home_page.dart`
- [ ] `lib/all_code/page/setting_page.dart`

### Priority 2 (Medium Usage)
- [ ] `lib/all_code/page/projects_gallery_page.dart`
- [ ] `lib/all_code/page/my_artworks_page.dart`
- [ ] `lib/all_code/page/paint_page.dart`
- [ ] `lib/presentation/pages/invitations_page.dart`

### Priority 3 (Low Usage)
- [ ] `lib/all_code/page/detail_page.dart`
- [ ] `lib/all_code/page/layer_paint_page.dart`

## Color Replacement Checklist

For each file, replace:

- [ ] `Colors.white` → `surfaceColor` or keep if intentional (like text on colored background)
- [ ] `Colors.black` → `textColor`
- [ ] `Colors.grey` → `subtitleColor` or `borderColor` depending on usage
- [ ] `Theme.of(context).primaryColor` → `primaryColor` (from helper)
- [ ] Hardcoded Color(0x...) → Appropriate AppColors constant
- [ ] Gradient colors → Use primaryColor with opacity variations

## Testing Checklist

After updating each page:

1. [ ] Test in Light Mode
   - Check all text is readable
   - Verify backgrounds are correct
   - Ensure buttons are visible
   
2. [ ] Test in Dark Mode
   - Check all text is readable (no black on dark gray)
   - Verify backgrounds don't blend together
   - Ensure sufficient contrast
   
3. [ ] Test Theme Switching
   - Switch between light and dark mode
   - Verify smooth transitions
   - Check no flashing or color errors

## Common Issues and Solutions

### Issue 1: Text not visible in dark mode
**Problem:** Using `Colors.black` on dark background
**Solution:** Use `textColor` variable instead

### Issue 2: Containers blend together
**Problem:** Using same color for container and background
**Solution:** Use `surfaceColor` for containers and `backgroundColor` for scaffold

### Issue 3: Borders disappear in dark mode
**Problem:** Using `Colors.grey[300]` which is too light
**Solution:** Use `borderColor.withOpacity(0.3)` for theme-aware borders

### Issue 4: Shadows not visible
**Problem:** Using `Colors.black.withOpacity(0.1)` in dark mode
**Solution:** 
```dart
BoxShadow(
  color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.2),
  blurRadius: 8,
)
```

## Example: Complete Page Update

### Before:
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Page', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: Card(
          color: Colors.grey[100],
          child: Text(
            'Content',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
```

### After:
```dart
import '../../constant/constant.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primaryColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: isDark ? 0 : 1,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Page',
          style: TextStyle(color: textColor),
        ),
      ),
      body: Container(
        child: Card(
          color: surfaceColor,
          elevation: isDark ? 4 : 2,
          child: Text(
            'Content',
            style: TextStyle(color: textColor),
          ),
        ),
      ),
    );
  }
}
```

## Quick Reference Table

| Use Case | Light Mode | Dark Mode | Variable Name |
|----------|-----------|-----------|---------------|
| Page Background | `AppColors.lightBackground` | `AppColors.darkBackground` | `backgroundColor` |
| Card/Surface | `AppColors.lightSurface` | `AppColors.darkSurface` | `surfaceColor` |
| Primary Action | `AppColors.lightAccent` | `AppColors.darkAccent` | `primaryColor` |
| Main Text | `Colors.black87` | `Colors.white` | `textColor` |
| Secondary Text | `Colors.black54` | `Colors.white70` | `subtitleColor` |
| Borders | `AppColors.lightSecondary` | `AppColors.darkSecondary` | `borderColor` |
| Dividers | `Colors.black12` | `Colors.white24` | Use directly |
| Shadows | `Colors.grey[200]` | `Colors.black45` | Use directly |

## Notes

1. **Always test both modes** after making changes
2. **Use opacity** for subtle variations: `primaryColor.withOpacity(0.1)`
3. **Consistent spacing** helps readability in both modes
4. **Icons** should use either `textColor` or `primaryColor`
5. **Elevation** may need adjustment: higher in dark mode for better depth perception

## Next Steps

1. Update QRIS Payment Page (in progress)
2. Update Marketplace Page
3. Update Home Page
4. Continue with remaining pages
5. Test all pages in both modes
6. Fix any issues found during testing

---

**Last Updated:** October 25, 2025
**Status:** In Progress - QRIS Payment Page being updated
