import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/session_reset.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔑 Soumission de la connexion par Email / Mot de passe
  Future<void> _handlePasswordSubmit() async {
    final identifiant = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifiant.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('login_fill_fields'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authRepository.connexion(identifiant, password);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      await invalidateSessionProviders(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('login_success')),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? context.tr('login_error'))),
      );
    }
  }

  /// 🌐 Soumission de la connexion Google Sign-In (vrai flux natif)
  Future<void> _handleGoogleSubmit() async {
    if (!AppConstants.isGoogleSignInConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('login_google_soon_message'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authRepository.signInWithGoogle();
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      await invalidateSessionProviders(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('login_google_success')),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/');
    } else if (res['cancelled'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? context.tr('login_google_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // En-tête centré avec Logo et Nom de l'application
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'LocaDirect CM',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('login_app_tagline'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                context.tr('login_email_password_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr('login_email_label'),
                  hintText: 'exemple@locadirect.cm',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('login_password_label'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordSubmit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('login_submit')),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(context.tr('login_or'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                ],
              ),

              const SizedBox(height: 16),

              // Bouton Connexion Google
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Image.asset('assets/images/google.png', width: 20, height: 20),
                label: Text(
                  AppConstants.isGoogleSignInConfigured
                      ? context.tr('login_google_continue')
                      : context.tr('login_google_soon'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                onPressed: _isLoading ? null : _handleGoogleSubmit,
              ),

              const SizedBox(height: 30),

              // Lien S'inscrire + Accès Invité rapide
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('login_no_account'), style: TextStyle(color: Colors.grey[400])),
                      GestureDetector(
                        onTap: () => context.push('/auth/register'),
                        child: Text(
                          context.tr('login_register_link'),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.explore, size: 18, color: AppColors.accentGold),
                    label: Text(context.tr('login_explore_demo'), style: const TextStyle(color: AppColors.accentGold)),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ],
      ),
    );
  }
}
