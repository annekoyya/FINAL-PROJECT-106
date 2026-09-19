import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/settings_controller.dart';
import '../../../data/repositories/word_repository.dart';

/// Lightweight settings screen (word list + core toggles). The fuller
/// "Game Preferences" group shown in the Profile mockup (Tile Theme,
/// High-Contrast, Haptics, Duel Invites) lives on ProfileScreen instead,
/// since the mockups show it embedded in the profile view - this screen
/// stays as a quick-access shortcut from the Dashboard's gear icon.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(backgroundColor: BrandColors.background, elevation: 0, title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.isDarkMode,
            onChanged: settings.toggleDarkMode,
          ),
          SwitchListTile(
            title: const Text('High-Contrast Tiles'),
            subtitle: const Text('Colorblind-friendly signs (orange/blue instead of green/yellow)'),
            value: settings.useHighContrastPalette,
            onChanged: settings.toggleHighContrast,
          ),
          SwitchListTile(
            title: const Text('Haptics & Feedback'),
            subtitle: const Text('Tactile keypad clicks'),
            value: settings.hapticsEnabled,
            onChanged: settings.toggleHaptics,
          ),
          SwitchListTile(
            title: const Text('Hard Mode'),
            subtitle: const Text('Revealed hints must be used in later guesses'),
            value: settings.hardMode,
            onChanged: settings.toggleHardMode,
          ),
          const Divider(),
          Consumer<WordRepository>(
            builder: (context, wordRepo, _) {
              return ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Update Word List'),
                subtitle: Text('${wordRepo.wordCount} words cached offline • unlimited via dictionary lookup'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final success = await wordRepo.refreshWordListFromRemote();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Word list updated (${wordRepo.wordCount} words cached)'
                              : 'Could not update — check your connection'),
                        ),
                      );
                    }
                  },
                  child: const Text('Refresh'),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Guesses are also checked against a live dictionary (dictionaryapi.dev), '
              'so valid words beyond the cached list are still accepted when online.',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}
