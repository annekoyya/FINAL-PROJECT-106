import 'package:flutter/material.dart';
import '../../../data/models/achievement.dart';
import '../../../data/repositories/achievements_repository.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repository = AchievementsRepository();
  Set<String> _unlocked = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _repository.loadUnlockedIds().then((ids) => setState(() {
          _unlocked = ids;
          _loaded = true;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: kAllAchievements.length,
              itemBuilder: (context, index) {
                final a = kAllAchievements[index];
                final unlocked = _unlocked.contains(a.id);
                return ListTile(
                  leading: Icon(
                    unlocked ? Icons.emoji_events : Icons.lock_outline,
                    color: unlocked ? Colors.amber : Colors.grey,
                  ),
                  title: Text(a.title, style: TextStyle(color: unlocked ? null : Colors.grey)),
                  subtitle: Text(a.description),
                );
              },
            ),
    );
  }
}
