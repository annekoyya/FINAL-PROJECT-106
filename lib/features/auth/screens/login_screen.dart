import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    try {
      await context.read<AuthRepository>().logInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _playAsGuest() async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthRepository>().signInAnonymously();
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
              const Text('Welcome Back!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Defend your global duel rank', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Duelist ID or Email',
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
                      : const Text('Log In to Duel'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _playAsGuest,
                  child: const Text('Instant Play as Guest'),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('OR SIGN IN WITH', style: TextStyle(fontSize: 12))),
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
                  onPressed: () => context.go('/signup'),
                  child: const Text('New challenger? Create an Account'),
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
