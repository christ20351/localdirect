import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import 'auth_provider.dart';

/// Écran de démarrage : vérifie si un jeton d'accès existe et reste valide
/// (GET /auth/moi — se rafraîchit automatiquement via l'intercepteur Dio si
/// besoin), puis redirige directement sans repasser par l'écran de connexion.
/// Un seul rôle (Locataire) a un parcours complet aujourd'hui : la redirection
/// "selon le rôle" se limite donc à l'accueil pour l'instant.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifierSession());
  }

  Future<void> _verifierSession() async {
    final user = await ref.read(authRepositoryProvider).getMoi();
    if (!mounted) return;

    final langue = user?['langue'] as String?;
    if (langue != null) {
      ref.read(localeProvider.notifier).setLanguageCode(langue);
    }

    context.go(user != null ? '/' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_rounded, color: AppColors.primary, size: 48),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
