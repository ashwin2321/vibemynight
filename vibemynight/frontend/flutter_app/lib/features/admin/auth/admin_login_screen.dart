import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

/// POST /auth/login matching Figma AdminLoginPage.tsx.
/// On success, AuthController flips to logged-in and GoRouter redirects to /admin/dashboard.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1578736641330-3155e606cd40?w=900&h=1100&fit=crop&auto=format',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.background.withValues(alpha: 0.85),
                          AppColors.neonPurple.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.nightlife, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'VibeMyNight',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Admin Portal',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Manage events, artists, passes, and inquiries from one place.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isWide) ...[
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.nightlife, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'VibeMyNight',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        const Text(
                          'Welcome back',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to your admin account',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 28),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'admin@vibemynight.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Sign In',
                          isLoading: _submitting,
                          onPressed: _submit,
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
