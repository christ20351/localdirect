import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/candidatures/presentation/candidatures_provider.dart';
import '../../features/alertes/presentation/alertes_provider.dart';
import '../../features/documents/presentation/documents_provider.dart';
import '../../features/bailleur/presentation/bailleur_provider.dart';
import '../../features/staff/presentation/staff_provider.dart';
import '../../features/visits/presentation/visites_provider.dart';
import '../../features/properties/presentation/property_provider.dart';

/// Invalide tous les providers qui contiennent des données propres à un compte
/// (candidatures, documents, biens, favoris...). Aucun d'entre eux
/// n'est `autoDispose` : sans cet appel, changer de compte dans la même
/// session app (déconnexion → connexion/inscription d'un autre compte, sans
/// redémarrer l'app) laisse apparaître les données de l'ancien utilisateur
/// tant qu'un écran ne les recharge pas manuellement.
/// À appeler après connexion, inscription ET déconnexion.
///
/// `favoritesProvider` est un cas particulier : c'est le seul provider de
/// session à persister sur disque (shared_preferences, clé unique non
/// scindée par compte). `ref.invalidate()` seul ne suffit pas — le nouveau
/// notifier recharge cette même clé au démarrage, donc SANS purge explicite
/// du cache disque, les favoris de l'ancien compte réapparaissent (ou
/// restent affichés après une déconnexion hors-ligne) avant même que l'appel
/// réseau `refresh()` n'ait eu la chance de corriger l'affichage. D'où
/// `await` ici : le cache doit être vidé AVANT que le nouveau notifier ne
/// soit reconstruit au prochain `watch`.
Future<void> invalidateSessionProviders(WidgetRef ref) async {
  await FavoritesNotifier.clearPersistedCache();

  ref.invalidate(currentUserProvider);
  ref.invalidate(isLoggedInProvider);
  ref.invalidate(candidaturesProvider);
  ref.invalidate(alertesProvider);
  ref.invalidate(favoritesProvider);
  ref.invalidate(mesDocumentsCompteProvider);
  ref.invalidate(mesBiensProvider);
  ref.invalidate(candidaturesRecuesProvider);
  ref.invalidate(mesBauxBailleurProvider);
  ref.invalidate(documentsEnAttenteProvider);
  ref.invalidate(biensEnAttenteProvider);
  ref.invalidate(visitesProvider);
}
