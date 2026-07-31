import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

/// Profil de l'utilisateur connecté (GET /auth/moi), `null` si non connecté.
/// `ref.invalidate(currentUserProvider)` après connexion/déconnexion/mise à jour
/// de profil pour forcer un rechargement.
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getMoi();
});

/// `true` si un jeton d'accès est stocké (ne garantit pas qu'il soit encore valide,
/// juste que l'utilisateur s'est connecté au moins une fois sans se déconnecter).
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final token = await repo.getAccessToken();
  return token != null;
});
