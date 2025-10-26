import 'package:flutter/material.dart';
import 'package:muraloka/constant/constant.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.primary,
        foregroundColor: theme.surface,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(color: theme.surface, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.surface,
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        children: [
          // Theme Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
          ),
          ListTile(
            leading: Icon(
              themeProvider.isDarkMode
                  ? PhosphorIcons.moon_fill
                  : PhosphorIcons.sun_fill,
              color: theme.primary,
            ),
            title: Text('Dark Mode', style: TextStyle(color: theme.textPrimary)),
            subtitle: Text(themeProvider.isDarkMode ? 'Enabled' : 'Disabled', style: TextStyle(color: theme.textSecondary)),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              activeColor: theme.primary,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.palette, color: theme.primary),
            title: Text('Theme Mode', style: TextStyle(color: theme.textPrimary)),
            subtitle: Text(_getThemeModeText(themeProvider.themeMode), style: TextStyle(color: theme.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: theme.textSecondary),
            onTap: () => _showThemeModeDialog(context, themeProvider),
          ),
          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.info, color: theme.primary),
            title: Text('App Version', style: TextStyle(color: theme.textPrimary)),
            subtitle: Text('1.0.0', style: TextStyle(color: theme.textSecondary)),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.github_logo, color: theme.primary),
            title: Text('Source Code', style: TextStyle(color: theme.textPrimary)),
            subtitle: Text('github.com/RIFZKI-ID/Muraloka', style: TextStyle(color: theme.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: theme.textSecondary),
            onTap: () {
              // Open GitHub repository
            },
          ),
          const Divider(),

          // Help & Support
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            ),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.question, color: theme.primary),
            title: Text('Help Center', style: TextStyle(color: theme.textPrimary)),
            trailing: Icon(Icons.chevron_right, color: theme.textSecondary),
            onTap: () {
              // Navigate to help center
            },
          ),
          ListTile(
            leading: Icon(PhosphorIcons.envelope_simple, color: theme.primary),
            title: Text('Contact Support', style: TextStyle(color: theme.textPrimary)),
            trailing: Icon(Icons.chevron_right, color: theme.textSecondary),
            onTap: () {
              // Open email client or contact form
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeModeDialog(BuildContext context, ThemeProvider themeProvider) {
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Select Theme Mode', style: TextStyle(color: theme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Light', style: TextStyle(color: theme.textPrimary)),
              subtitle: Text('Always use light theme', style: TextStyle(color: theme.textSecondary)),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              activeColor: theme.primary,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark', style: TextStyle(color: theme.textPrimary)),
              subtitle: Text('Always use dark theme', style: TextStyle(color: theme.textSecondary)),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              activeColor: theme.primary,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('System Default', style: TextStyle(color: theme.textPrimary)),
              subtitle: Text('Follow system theme', style: TextStyle(color: theme.textSecondary)),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              activeColor: theme.primary,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
