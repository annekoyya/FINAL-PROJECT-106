import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';

/// Minimal placeholder screen. A full friend-request flow (send/accept via
/// Cloud Function, subcollections on both users) is described as a
/// stretch phase in the project's PBL roadmap - this screen is wired up
/// so the bottom nav / routes are complete, but the actual request
/// send/accept logic is not implemented in this zip. See README.md
/// "Next Steps" for the data model to build this out.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(backgroundColor: BrandColors.background, elevation: 0, title: const Text('Friends')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 48, color: BrandColors.primary),
              const SizedBox(height: 12),
              const Text(
                "You haven't added any friends yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Invite someone to duel and climb the friends leaderboard together.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Invite a Friend'),
                onPressed: () => Share.share('Join me on Wordie! Let\'s duel over word puzzles.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
