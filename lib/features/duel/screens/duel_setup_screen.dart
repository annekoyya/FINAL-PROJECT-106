import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/duel_repository.dart';
import '../../../data/repositories/word_repository.dart';
import '../../../core/utils/firebase_error_helper.dart';

/// Matches "Wordie - Duel Setup & ..." mockup: word length + word pack
/// pickers, then a room-created state with a shareable code.
class DuelSetupScreen extends StatefulWidget {
  const DuelSetupScreen({super.key});

  @override
  State<DuelSetupScreen> createState() => _DuelSetupScreenState();
}

class _DuelSetupScreenState extends State<DuelSetupScreen> {
  int _wordLength = 5;
  String _wordPack = 'General';
  bool _creating = false;
  String? _roomCode;
  String? _duelId;
  String? _error;

  Future<void> _createRoom() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthRepository>();
      final wordRepository = context.read<WordRepository>();
      final duelRepository = context.read<DuelRepository>();

      var uid = auth.currentUser?.uid;
      uid ??= (await auth.signInAnonymously())?.uid;
      if (uid == null) throw StateError('Could not establish a session.');

      final secretWord = wordRepository.randomWord();
      final duel = await duelRepository.createDuel(
        hostUid: uid,
        hostDisplayName: auth.currentUser?.displayName ?? 'Player',
        secretWord: secretWord,
        wordLength: _wordLength,
        wordPack: _wordPack,
      );

      setState(() {
        _roomCode = duel.roomCode;
        _duelId = duel.id;
      });
    } catch (e) {
setState(() => _error = 'Could not create room: ${describeFirebaseError(e)}');    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        title: Text(_roomCode == null ? 'Challenge a Friend' : 'Room Created'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _roomCode == null ? _buildSetupForm() : _buildWaitingRoom(),
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose word length', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [4, 5, 6, 7].map((len) {
            final selected = len == _wordLength;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$len'),
                selected: selected,
                selectedColor: BrandColors.accentMint,
                onSelected: (_) => setState(() => _wordLength = len),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Choose word pack', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['General', 'Animals', 'Tech'].map((pack) {
            final selected = pack == _wordPack;
            return ChoiceChip(
              label: Text(pack),
              selected: selected,
              selectedColor: BrandColors.accentMint,
              onSelected: (_) => setState(() => _wordPack = pack),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        const Text('Settings lock once the room is created.',
            style: TextStyle(fontSize: 12, color: Colors.black45)),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.textDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _creating ? null : _createRoom,
            child: _creating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create Room'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.push('/game/practice'),
            child: const Text('Practice solo first? Play Daily'),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingRoom() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('Share this code:', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
            border: Border.all(color: BrandColors.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_roomCode!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _roomCode!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
              },
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () => Share.share('Join my Wordie duel! Room code: $_roomCode'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder(
          stream: context.read<DuelRepository>().watchDuel(_duelId!),
          builder: (context, snapshot) {
            final duel = snapshot.data;
            if (duel != null && duel.player2Id != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.pushReplacement('/duel/$_duelId');
              });
            }
            return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Waiting for opponent...'),
              ],
            );
          },
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
