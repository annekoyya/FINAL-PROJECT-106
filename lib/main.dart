import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/settings_controller.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/duel_repository.dart';
import 'data/repositories/firebase_sync_repository.dart';
import 'data/repositories/leaderboard_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/word_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALIZE FIREBASE FIRST! 
  // This must happen before ANY repository that might touch Firebase is created.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed or not configured: $e');
  }

  // 2. NOW it is safe to instantiate repositories
  final wordRepository = WordRepository();
  await wordRepository.load();

  final settingsController = SettingsController(SettingsRepository());
  await settingsController.load();

  final authRepository = AuthRepository();
  final duelRepository = DuelRepository();

  FirebaseSyncRepository? firebaseSyncRepository;
  LeaderboardRepository? leaderboardRepository;

  // 3. Only use Firebase-dependent features if initialization succeeded
  if (Firebase.apps.isNotEmpty) {
    firebaseSyncRepository = FirebaseSyncRepository();
    leaderboardRepository = LeaderboardRepository();

    try {
      // Zero-friction entry point: anonymous sign-in
      await authRepository.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
  } else {
    debugPrint('Running in local-only mode (Firebase not configured).');
  }

  runApp(WordieApp(
    wordRepository: wordRepository,
    settingsController: settingsController,
    authRepository: authRepository,
    duelRepository: duelRepository,
    firebaseSyncRepository: firebaseSyncRepository,
    leaderboardRepository: leaderboardRepository,
  ));
}

class WordieApp extends StatelessWidget {
  final WordRepository wordRepository;
  final SettingsController settingsController;
  final AuthRepository authRepository;
  final DuelRepository duelRepository;
  final FirebaseSyncRepository? firebaseSyncRepository;
  final LeaderboardRepository? leaderboardRepository;

  const WordieApp({
    super.key,
    required this.wordRepository,
    required this.settingsController,
    required this.authRepository,
    required this.duelRepository,
    required this.firebaseSyncRepository,
    required this.leaderboardRepository,
  });

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(wordRepository: wordRepository);

    return MultiProvider(
      providers: [
        Provider<WordRepository>.value(value: wordRepository),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<DuelRepository>.value(value: duelRepository),
        Provider<FirebaseSyncRepository?>.value(value: firebaseSyncRepository),
        Provider<LeaderboardRepository?>.value(value: leaderboardRepository),
        ChangeNotifierProvider<SettingsController>.value(value: settingsController),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Wordie',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}