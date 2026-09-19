import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/settings_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/game_preferences_repository.dart';
import '../../../data/repositories/stats_repository.dart';

/// Matches "Wordie - Player Profile": identity header, career highlight
/// cards, and the Game Preferences toggle group (Tile Theme /
/// High-Contrast / Haptics / Duel Invites).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _gamesPlayed = 0;
  double _winRate = 0;
  int _streak = 0;
  int _bestGuess = 0;

  @override
  void initState() {
    super.initState();
    StatsRepository().load().then((stats) {
      if (!mounted) return;
      setState(() {
        _gamesPlayed = stats.gamesPlayed;
        _winRate = stats.winRate;
        _streak = stats.currentStreak;
        final firstNonZero = stats.guessDistribution.indexWhere((c) => c > 0);
        _bestGuess = firstNonZero == -1 ? 0 : firstNonZero + 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final settings = context.watch<SettingsController>();
    final user = auth.currentUser;
    final isGuest = auth.isAnonymous;

    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(backgroundColor: BrandColors.background, elevation: 0, title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: BrandColors.primary.withOpacity(0.2),
                child: Text(
                  (user?.displayName?.isNotEmpty == true ? user!.displayName![0] : 'W').toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user?.displayName ?? (isGuest ? 'Guest Player' : 'Player'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                isGuest ? 'Playing as guest — data is local only' : user?.email ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),
            if (isGuest)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: BrandColors.accentGold.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Sign up to save your streak and sync across devices.', style: TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/signup'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('CAREER HIGHLIGHTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _HighlightCard(label: 'Matches', value: '$_gamesPlayed')),
                const SizedBox(width: 8),
                Expanded(child: _HighlightCard(label: 'Win Rate', value: '${(_winRate * 100).round()}%')),
                const SizedBox(width: 8),
                Expanded(child: _HighlightCard(label: 'Best', value: _bestGuess == 0 ? '—' : '$_bestGuess')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('GAME PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _PreferenceCard(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: settings.isDarkMode,
                  onChanged: settings.toggleDarkMode,
                ),
                SwitchListTile(
                  title: const Text('High-Contrast Tiles'),
                  subtitle: const Text('Colorblind-friendly signs'),
                  value: settings.useHighContrastPalette,
                  onChanged: settings.toggleHighContrast,
                ),
                SwitchListTile(
                  title: const Text('Haptics & Feedback'),
                  subtitle: const Text('Tactile keypad clicks'),
                  value: settings.hapticsEnabled,
                  onChanged: settings.toggleHaptics,
                ),
                ListTile(
                  title: const Text('Duel Invites'),
                  subtitle: Text('Who can ping you for live matches: ${_labelFor(settings.duelInvitePolicy)}'),
                  trailing: DropdownButton<DuelInvitePolicy>(
                    value: settings.duelInvitePolicy,
                    items: DuelInvitePolicy.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(_labelFor(p))))
                        .toList(),
                    onChanged: (p) {
                      if (p != null) settings.setDuelInvitePolicy(p);
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text('Hard Mode'),
                  subtitle: const Text('Revealed hints must be used in later guesses'),
                  value: settings.hardMode,
                  onChanged: settings.toggleHardMode,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!isGuest)
              OutlinedButton(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Log Out'),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text('Wordie v1.0.0', style: TextStyle(fontSize: 11, color: Colors.black38)),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(DuelInvitePolicy policy) {
    switch (policy) {
      case DuelInvitePolicy.everyone:
        return 'Everyone';
      case DuelInvitePolicy.friendsOnly:
        return 'Friends Only';
      case DuelInvitePolicy.noOne:
        return 'No One';
    }
  }
}

class _HighlightCard extends StatelessWidget {
  final String label;
  final String value;
  const _HighlightCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final List<Widget> children;
  const _PreferenceCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}