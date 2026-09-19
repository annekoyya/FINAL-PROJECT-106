import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/word_repository.dart';

/// Matches the "Wordie - Dashboard" mockup: streak/rank strip, daily
/// puzzle card, duel card, quick stats, bottom nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _gamesPlayed = 0;
  double _winRate = 0;
  int _currentStreak = 0;
  int _bestGuess = 0;

  @override
  void initState() {
    super.initState();
    StatsRepository().load().then((stats) {
      if (!mounted) return;
      setState(() {
        _gamesPlayed = stats.gamesPlayed;
        _winRate = stats.winRate;
        _currentStreak = stats.currentStreak;
        final firstNonZero = stats.guessDistribution.indexWhere((c) => c > 0);
        _bestGuess = firstNonZero == -1 ? 0 : firstNonZero + 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordRepository = context.watch<WordRepository>();

    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        leading: const Icon(Icons.menu, color: BrandColors.textDark),
        title: const Text('Wordie', style: TextStyle(color: BrandColors.textDark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: BrandColors.textDark),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PillStat(
                      icon: Icons.local_fire_department,
                      label: '$_currentStreak-Day Streak',
                      color: BrandColors.accentGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PillStat(
                      icon: Icons.emoji_events,
                      label: 'Rank #482',
                      color: BrandColors.accentMint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TODAY'S DAILY PUZZLE",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    const Text('● Not played yet', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.accentMint,
                          foregroundColor: BrandColors.textDark,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Daily Puzzle'),
                        onPressed: () => context.push('/game/daily'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_kabaddi, size: 18),
                        SizedBox(width: 6),
                        Text('Challenge a Friend', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('1v1 Duel Mode • Race a friend to the word',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/duel/setup'),
                            child: const Text('Create Duel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/duel/join'),
                            child: const Text('Join Code'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QUICK STATS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _QuickStat(value: '$_gamesPlayed', label: 'Games'),
                        _QuickStat(value: '${(_winRate * 100).round()}%', label: 'Win %'),
                        _QuickStat(value: _bestGuess == 0 ? '—' : '$_bestGuess', label: 'Best'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${wordRepository.wordCount} words available offline',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: BrandColors.background,
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Leaders'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.push('/stats');
              break;
            case 2:
              context.push('/leaderboard');
              break;
            case 3:
              context.push('/friends');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _PillStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PillStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: BrandColors.textDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: BrandColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  const _QuickStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
