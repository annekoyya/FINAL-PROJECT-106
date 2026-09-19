import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/duel_repository.dart';

class DuelJoinScreen extends StatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  State<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends State<DuelJoinScreen> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthRepository>();
      final duelRepository = context.read<DuelRepository>();
      
      var uid = auth.currentUser?.uid;
      uid ??= (await auth.signInAnonymously())?.uid;
      if (uid == null) throw StateError('Could not establish a session.');

      if (!mounted) return;

      final duel = await duelRepository.joinDuel(
        roomCode: _codeController.text.trim(),
        joinerUid: uid,
        joinerDisplayName: auth.currentUser?.displayName ?? 'Player',
      );

      if (mounted) context.pushReplacement('/duel/${duel.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not join room: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        title: const Text('Join a Duel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter the room code your friend shared with you:'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Room Code', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joining ? null : _join,
              child: _joining
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join Duel'),
            ),
          ],
        ),
      ),
    );
  }
}