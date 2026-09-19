import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../data/models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: BrandColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: BrandColors.primary,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
            Tab(text: 'Duel Elo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardTab(type: 'Global'),
          _LeaderboardTab(type: 'Friends'),
          _LeaderboardTab(type: 'Duel Elo'),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final String type;
  const _LeaderboardTab({required this.type});

  @override
  Widget build(BuildContext context) {
    // Placeholder UI until Firestore queries are fully wired
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: BrandColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            '$type Leaderboard',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data will populate here once Firestore is connected.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}