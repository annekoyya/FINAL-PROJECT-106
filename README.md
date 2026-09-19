# Wordie — Flutter + Firebase Word-Duel Game

**Paste this whole README into a new chat to give an AI assistant full context on this project before asking for further changes.**

---

## 1. What This Project Is

Wordie is a Flutter (Dart) mobile word-guessing game in the Wordle family, extended with async 1v1 duels, a ranked Elo ladder, leaderboards, achievements, and a real account system — while still working as a fully offline solo game if Firebase isn't configured. It matches the "Wordie" mockups (Dashboard, Duel Setup, Live Duel, Leaderboard, Match Result, Stats, Sign Up, Login, Player Profile) and the accompanying project documentation.

**Word supply is effectively unlimited**: instead of relying only on a bundled or downloaded word list, every guess is checked against the free [dictionaryapi.dev](https://dictionaryapi.dev) dictionary API when it isn't already in the local list — see Section 4.

---

## 2. Feature State

**Implemented:**
- Daily / Practice / Timed solo modes (deterministic daily word, no server required)
- **Unlimited word validation via a live dictionary API**, with local-list-first, offline-safe fallback (Section 4)
- Async 1v1 Duel Mode: create a room, share a code, both players solve the same secret word on their own time; winner determined by fewest guesses then fastest time
- Elo rating calculation for ranked duels (client-side in this zip — see the security note in Section 5)
- Leaderboard with Friends / Global / Duel Elo tabs (Firestore-backed)
- Stats screen with time-range tabs (All Time / This Month / Duels Only — see note in the file about what's actually wired up), guess distribution, recent badges
- Achievements system (solo mode) + a lightweight duel-specific achievement callout on the Match Result screen
- Auth: Sign Up, Login, Google Sign-In, and zero-friction anonymous "Guest" play with upgrade-in-place (no data loss) to a real account
- Player Profile screen: identity, career highlights, and game preference toggles (Dark Mode, High-Contrast Tiles, Haptics & Feedback, Duel Invites policy, Hard Mode)
- Local persistence for daily-game-in-progress and stats; haptic feedback on keypresses (toggleable)
- Share results (emoji grid for solo, summary text for duels)

**Explicitly stubbed / not fully implemented (said out loud, not hidden):**
- **Apple Sign-In** — `AuthRepository.signInWithApple()` throws `UnimplementedError` with a message pointing here. Apple Sign-In needs Xcode capability + Services ID configuration that can't be done from a zipped project; wire up the `sign_in_with_apple` package once that's set up.
- **Friends system** — `FriendsScreen` is a placeholder UI with an invite share button; the actual send/accept friend-request data model is *not* built. See Section 6 for the intended Firestore shape.
- **Server-side duel fairness** — see Section 5, this is the most important caveat in the whole project.
- **Stats time-range filtering** — "This Month" and "Duels Only" tabs exist in the UI but currently show the same aggregate numbers as "All Time," since games aren't individually timestamped/tagged yet.

---

## 3. Project Structure

```
wordie/
├── pubspec.yaml
├── README.md
├── assets/words/
│   ├── answers.json           # small bundled fallback word list
│   ├── valid_guesses.json     # small bundled fallback guess list
│   └── definitions.json       # bundled definitions subset
├── lib/
│   ├── main.dart               # entry point: loads repos, tries Firebase init, anonymous sign-in
│   ├── app_router.dart         # go_router route table (all screens below)
│   ├── firebase_options.dart   # PLACEHOLDER — run `flutterfire configure`
│   │
│   ├── core/theme/
│   │   ├── app_colors.dart          # TileColors, KeyboardColors, BrandColors, ThemeData
│   │   └── settings_controller.dart # ChangeNotifier: dark mode, high-contrast, haptics, hard mode, duel invites
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── letter_status.dart, guess_result.dart, stats.dart, achievement.dart, game_mode.dart
│   │   │   ├── user_profile.dart        # NEW
│   │   │   ├── duel.dart, duel_status.dart   # NEW
│   │   │   └── leaderboard_entry.dart   # NEW
│   │   ├── logic/
│   │   │   ├── guess_evaluator.dart     # duplicate-letter-safe algorithm, unit tested
│   │   │   └── elo_calculator.dart      # NEW — ranked rating math
│   │   └── repositories/
│   │       ├── word_repository.dart            # UPDATED — async, dictionary-API-backed validation
│   │       ├── dictionary_api_service.dart      # NEW — unlimited word validation + definitions
│   │       ├── remote_word_list_service.dart    # downloads/caches an expandable word list
│   │       ├── auth_repository.dart             # NEW — email/Google/anonymous auth
│   │       ├── duel_repository.dart             # NEW — Firestore-backed async duels
│   │       ├── leaderboard_repository.dart      # NEW — Friends/Global/Duel Elo queries
│   │       ├── game_preferences_repository.dart # NEW — haptics/high-contrast/duel-invite persistence
│   │       ├── game_state_repository.dart, stats_repository.dart, settings_repository.dart, achievements_repository.dart
│   │       └── firebase_sync_repository.dart    # solo-mode cloud stats sync + daily leaderboard
│   │
│   └── features/
│       ├── auth/screens/sign_up_screen.dart, login_screen.dart          # NEW
│       ├── home/screens/home_screen.dart          # REWRITTEN — Dashboard matching mockup
│       ├── game/                                   # solo Daily/Practice/Timed (logic, widgets, screens)
│       ├── duel/                                   # NEW
│       │   ├── logic/duel_controller.dart
│       │   ├── screens/duel_setup_screen.dart, duel_join_screen.dart, live_duel_screen.dart, match_result_screen.dart
│       ├── stats/screens/stats_screen.dart         # REWRITTEN — tabs + badges
│       ├── achievements/                            # unchanged from prior version
│       ├── leaderboard/screens/leaderboard_screen.dart  # REWRITTEN — Friends/Global/Duel Elo tabs
│       ├── profile/screens/profile_screen.dart     # NEW
│       ├── friends/screens/friends_screen.dart     # NEW (placeholder)
│       └── settings/screens/settings_screen.dart   # quick-access subset of Profile's preferences
│
└── test/guess_evaluator_test.dart
```

---

## 4. How "Unlimited Words" Works

`WordRepository.isValidGuess(word)` now checks, in order:
1. **Local list** (bundled + any previously downloaded/cached words) — instant, works fully offline.
2. **Live dictionary API** (`DictionaryApiService`, wrapping `https://api.dictionaryapi.dev`, no API key needed) — if the word isn't locally known, it's looked up live. A 200 response means it's a real word and gets cached into the in-memory list for the rest of the session; a 404 means it's confirmed not a word; a network failure is treated as "unconfirmed" and currently falls back to rejecting the guess (see the comment in `word_repository.dart` for the reasoning — fails closed rather than silently accepting anything when offline).

This means the daily/practice word pool can still be small (bundled JSON), while the set of **guesses** a player can type is effectively the entire English dictionary, online. `DictionaryApiService.definitionFor()` also backs the word-definition feature (bundled `definitions.json` first, live API fallback second).

`GameController` and `DuelController` both call this asynchronously now — the UI shows a brief "Checking word…" spinner while the API call is in flight, and the keyboard/grid are disabled during that window so double-submits can't happen.

---

## 5. ⚠️ Important Security Note: Duel Mode Is Not Cheat-Proof Yet

`DuelRepository` stores the secret word directly on the Firestore duel document and evaluates guesses **client-side**, so Duel Mode is fully demoable without deploying any backend code. **This is not safe for a real competitive release** — a technically curious player could read the secret word directly out of Firestore before guessing.

The fix is architectural, not a full rewrite: move `GuessEvaluator.evaluate()` and the winner-determination logic in `DuelRepository.submitResult()` into a **Cloud Function**, store the secret word in a Firestore collection with security rules that deny all client reads, and have the app call the function instead of reading/writing the duel document directly for anything guess-related. The logic itself doesn't change — only *where* it runs. This exact migration is documented in more depth in the project's companion PBL guide (Phase 2 of the "WordClash" roadmap, if you have it) — treat that as the reference for the Cloud Function code to write.

Elo updates (`DuelRepository.applyEloUpdate`) have the same caveat: currently called client-side after a duel finishes, should move server-side (a Firestore trigger on `duels/{id}` transitioning to "finished") before this is treated as a tamper-proof ranked ladder.

---

## 6. Running Locally

```bash
flutter pub get
flutter run
```

Solo modes (Daily/Practice/Timed) work fully offline. Duel Mode, Leaderboard, and account sync require Firebase — see Section 7.

Run tests:
```bash
flutter test
```

---

## 7. Firebase Setup

1. Create a project at https://console.firebase.google.com
2. `dart pub global activate flutterfire_cli` then `flutterfire configure` from this project's root — this overwrites `lib/firebase_options.dart` with real config.
3. Enable **Anonymous** and **Email/Password** and **Google** sign-in methods under Authentication.
4. Enable **Firestore** (test mode for development). Minimum collections used: `users/{uid}`, `duels/{duelId}`.
5. Suggested production security rules:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read: if true; // needed for leaderboard queries
         allow write: if request.auth != null && request.auth.uid == userId;
       }
       match /duels/{duelId} {
         allow read: if request.auth != null;
         // NOTE: once evaluation moves to Cloud Functions (Section 5),
         // tighten this to deny direct client writes entirely.
         allow write: if request.auth != null;
       }
     }
   }
   ```
6. For Google Sign-In on Android, add your SHA-1 fingerprint in the Firebase console (Project Settings → your Android app).
7. For Apple Sign-In: not wired up yet — see Section 2.

---

## 8. Suggested Next Steps (in rough priority order)

1. **Harden Duel Mode** per Section 5 — this is the single most important gap before showing this to anyone as "competitive."
2. **Build the real friends system** — `users/{uid}/friends/{friendUid}` subcollections written via a Cloud Function on request-accept (mirrored on both sides), replacing the current `FriendsScreen` placeholder. `LeaderboardRepository.watchFriends()` already expects a `List<String>` of friend uids, so the query side is ready.
3. **Tag games with a type + timestamp** so the Stats screen's "This Month" / "Duels Only" tabs can filter for real instead of showing the same numbers as "All Time."
4. **Expand the bundled word lists** in `assets/words/` — they're intentionally small for fast local testing.
5. **Wire up Apple Sign-In** once Xcode/Services ID configuration is done outside this codebase.

---

## 9. How to Continue This Project in a New Chat

A good first message alongside this README:

> "Here's the README for my Flutter app Wordie. I want to [harden Duel Mode with Cloud Functions / build the friends system / expand word lists / something else]. Please read the README for the current architecture, what's stubbed vs. real, and the security caveat in Section 5 before making changes."
# FINAL-PROJECT-106
