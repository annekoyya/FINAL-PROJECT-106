import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/stats.dart';
import '../../../data/repositories/achievements_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../widgets/distribution_bar.dart';

/// Matches "Wordie - Statistics & ...": time-range tabs (kept as UI
/// scaffolding — see note below), summary cards, guess distribution,
/// and a recent-badges preview linking to the full Achievements screen.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _statsRepository = StatsRepository();
  final _achievementsRepository = AchievementsRepository();
  Stats? _stats;
  Set<String> _unlockedIds = {};
  int _selectedTab = 0; // 0 = All Time, 1 = This Month, 2 = Duels Only

  @override
  void initState() {
    super.initState();
    _statsRepository.load().then((s) => setState(() => _stats = s));
    _achievementsRepository.loadUnlockedIds().then((ids) => setState(() => _unlockedIds = ids));
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(backgroundColor: BrandColors.background, elevation: 0, title: const Text('Stats')),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NOTE: "This Month" and "Duels Only" currently show the
                  // same aggregate data as "All Time" - Stats is only
                  // tracked in one running total right now. To split this
                  // out for real, timestamp each finished game (daily +
                  // duel) and filter/aggregate by date range and game type
                  // when building this view, rather than reading a single
                  // pre-summed Stats object.
                  Row(
                    children: List.generate(3, (i) {
                      const labels = ['All Time', 'This Month', 'Duels Only'];
                      final selected = _selectedTab == i;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ChoiceChip(
                            label: Text(labels[i], style: const TextStyle(fontSize: 12)),
                            selected: selected,
                            selectedColor: BrandColors.accentMint,
                            onSelected: (_) => setState(() => _selectedTab = i),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Matches', value: '${stats.gamesPlayed}')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Win Rate',
                          value: '${(stats.winRate * 100).round()}%',
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Streak', value: '${stats.currentStreak} 🔥')),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(label: 'Best Streak', value: '${stats.maxStreak}')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Guess Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(6, (i) {
                    final maxCount = stats.guessDistribution.isEmpty
                        ? 0
                        : stats.guessDistribution.reduce((a, b) => a > b ? a : b);
                    return DistributionBar(
                      guessNumber: i + 1,
                      count: stats.guessDistribution[i],
                      maxCount: maxCount,
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_unlockedIds.length} of ${kAllAchievements.length}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...kAllAchievements.take(3).map((a) => _BadgeTile(
                        achievement: a,
                        unlocked: _unlockedIds.contains(a.id),
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/achievements'),
                    child: const Text('View All Achievements'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatCard({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? BrandColors.accentMint : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _BadgeTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked ? BrandColors.accentGold.withOpacity(0.35) : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(unlocked ? Icons.emoji_events : Icons.lock_outline, color: unlocked ? Colors.amber.shade700 : Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(achievement.description, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
