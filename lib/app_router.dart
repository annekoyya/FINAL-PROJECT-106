import 'package:go_router/go_router.dart';
import 'data/models/game_mode.dart';
import 'data/repositories/word_repository.dart';
import 'features/achievements/screens/achievements_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/duel/screens/duel_join_screen.dart';
import 'features/duel/screens/duel_setup_screen.dart';
import 'features/duel/screens/live_duel_screen.dart';
import 'features/friends/screens/friends_screen.dart';
import 'features/game/screens/game_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/stats/screens/stats_screen.dart';

GoRouter buildRouter({required WordRepository wordRepository}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

      // Auth
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Solo game modes
      GoRoute(path: '/game/daily', builder: (context, state) => const GameScreen(mode: GameMode.daily)),
      GoRoute(path: '/game/practice', builder: (context, state) => const GameScreen(mode: GameMode.practice)),
      GoRoute(path: '/game/timed', builder: (context, state) => const GameScreen(mode: GameMode.timed)),

      // Duel mode
      GoRoute(path: '/duel/setup', builder: (context, state) => const DuelSetupScreen()),
      GoRoute(path: '/duel/join', builder: (context, state) => const DuelJoinScreen()),
      GoRoute(
        path: '/duel/:id',
        builder: (context, state) => LiveDuelScreen(duelId: state.pathParameters['id']!),
      ),

      // Stats / social / meta
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
      GoRoute(path: '/achievements', builder: (context, state) => const AchievementsScreen()),
      GoRoute(path: '/leaderboard', builder: (context, state) => const LeaderboardScreen()),
      GoRoute(path: '/friends', builder: (context, state) => const FriendsScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
}
