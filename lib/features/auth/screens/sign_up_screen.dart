import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';

/// Matches the "Join the Clash" mockup. Since Wordie auto-signs the player
/// in anonymously on first launch (see main.dart), this screen's real job
/// is *upgrading* that anonymous session to a real account so stats and
/// streak survive a reinstall/device change - not creating a brand new
/// identity from scratch.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final auth = context.read<AuthRepository>();
    try {
      if (auth.isAnonymous && auth.isSignedIn) {
        await auth.linkEmailToAnonymousAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _usernameController.text.trim(),
        );
      }
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.abc, color: BrandColors.primary),
                  SizedBox(width: 8),
                  Text('Wordie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Join the Clash ✨',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Create an account to save streaks, sync across devices, and duel on the ranked competitive ladder.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Arena Tag / Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 8),
              const Text(
                'Must be at least 8 chars, 1 number & 1 symbol.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Free Account →'),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('OR CONTINUE WITH', style: TextStyle(fontSize: 12))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Google'),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              try {
                                await context.read<AuthRepository>().signInWithGoogle();
                                if (mounted) context.go('/');
                              } catch (e) {
                                setState(() => _error = e.toString());
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.apple),
                      label: const Text('Apple'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Apple Sign-In needs platform setup - see README.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Log In'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
