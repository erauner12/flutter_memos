import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode; // Import only ThemeMode
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeSelectorScreen extends ConsumerWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current theme mode
    final currentThemeMode = ref.watch(themeModeProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Theme'),
      ),
      child: SafeArea(
        child: CupertinoListSection(
          header: const Text('APPEARANCE'),
          children: [
            _buildThemeOption(
              context,
              ref,
              title: 'Light',
              themeMode: ThemeMode.light,
              isSelected: currentThemeMode == ThemeMode.light,
            ),
            _buildThemeOption(
              context,
              ref,
              title: 'Dark',
              themeMode: ThemeMode.dark,
              isSelected: currentThemeMode == ThemeMode.dark,
            ),
            _buildThemeOption(
              context,
              ref,
              title: 'System',
              themeMode: ThemeMode.system,
              isSelected: currentThemeMode == ThemeMode.system,
              subtitle: 'Use your device settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required ThemeMode themeMode,
    required bool isSelected,
    String? subtitle,
  }) {
    return CupertinoListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: isSelected
          ? const Icon(
              CupertinoIcons.check_mark,
              color: CupertinoColors.activeBlue,
            )
          : null,
      onTap: () {
        // Set the new theme mode
        ref.read(setThemeModeProvider)(themeMode);
        // Navigate back (optional, depending on your navigation flow)
        Navigator.of(context).pop();
      },
    );
  }
}
