import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';
import '../../../core/network/api_client.dart';

/// Ville ouverte telle que renvoyée par `/villes` — le `slug` est ce qui compte
/// pour filtrer les annonces, le `nom` n'est que pour l'affichage.
class VilleOption {
  final String id;
  final String nom;
  final String slug;

  const VilleOption({required this.id, required this.nom, required this.slug});

  factory VilleOption.fromJson(Map<String, dynamic> json) {
    return VilleOption(
      id: json['id'] as String,
      nom: json['nom'] as String,
      slug: json['slug'] as String,
    );
  }
}

/// Quartier actif d'une ville, tel que renvoyé par `/villes/:slug/quartiers`.
class QuartierOption {
  final String id;
  final String nom;
  final String slug;

  const QuartierOption({required this.id, required this.nom, required this.slug});

  factory QuartierOption.fromJson(Map<String, dynamic> json) {
    return QuartierOption(
      id: json['id'] as String,
      nom: json['nom'] as String,
      slug: json['slug'] as String,
    );
  }
}

/// Filtres de recherche étendus (budget, avance, meublé, nb pièces).
/// `meuble` : `null` = indifférent, `true`/`false` = filtré.
class RechercheFiltres {
  final int? loyerMin;
  final int? loyerMax;
  final int? avanceMax;
  final bool? meuble;
  final int? nbPieces;

  const RechercheFiltres({this.loyerMin, this.loyerMax, this.avanceMax, this.meuble, this.nbPieces});

  bool get estVide => loyerMin == null && loyerMax == null && avanceMax == null && meuble == null && nbPieces == null;

  int get nbActifs => [loyerMin, loyerMax, avanceMax, meuble, nbPieces].where((v) => v != null).length;

  RechercheFiltres copyWith({
    int? loyerMin,
    bool clearLoyerMin = false,
    int? loyerMax,
    bool clearLoyerMax = false,
    int? avanceMax,
    bool clearAvanceMax = false,
    bool? meuble,
    bool clearMeuble = false,
    int? nbPieces,
    bool clearNbPieces = false,
  }) {
    return RechercheFiltres(
      loyerMin: clearLoyerMin ? null : (loyerMin ?? this.loyerMin),
      loyerMax: clearLoyerMax ? null : (loyerMax ?? this.loyerMax),
      avanceMax: clearAvanceMax ? null : (avanceMax ?? this.avanceMax),
      meuble: clearMeuble ? null : (meuble ?? this.meuble),
      nbPieces: clearNbPieces ? null : (nbPieces ?? this.nbPieces),
    );
  }
}

// Service API d'accès aux annonces et référentiels géographiques
class PropertiesRepository {
  final Dio _dio = ApiClient.dio;

  /// 🏙️ Récupérer les villes ouvertes depuis l'API NestJS (/api/v1/villes)
  Future<List<VilleOption>> fetchVilles() async {
    try {
      final response = await _dio.get('/villes');
      final List data = response.data;
      return data.map((json) => VilleOption.fromJson(json)).toList();
    } catch (_) {
      return const [
        VilleOption(id: 'douala', nom: 'Douala', slug: 'douala'),
        VilleOption(id: 'yaounde', nom: 'Yaoundé', slug: 'yaounde'),
      ]; // Fallback local si l'API est indisponible
    }
  }

  /// 📍 Récupérer les quartiers actifs d'une ville (/villes/:slug/quartiers)
  Future<List<QuartierOption>> fetchQuartiers(String villeSlug) async {
    try {
      final response = await _dio.get('/villes/$villeSlug/quartiers');
      final List data = response.data;
      return data.map((json) => QuartierOption.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 🔍 Récupérer le catalogue d'annonces dynamiques (/api/v1/annonces)
  /// `villeSlug`/`quartierSlug` doivent être des slugs (ex: "yaounde", pas "Yaoundé")
  /// tels que renvoyés par `/villes` : l'API filtre par égalité de slug exacte.
  Future<List<PropertyModel>> fetchAnnonces({
    String? villeSlug,
    String? quartierSlug,
    String? type,
    RechercheFiltres? filtres,
  }) async {
    try {
      final response = await _dio.get('/annonces', queryParameters: {
        if (villeSlug != null) 'ville': villeSlug,
        if (quartierSlug != null) 'quartier': quartierSlug,
        if (type != null) 'type': type,
        if (filtres?.loyerMin != null) 'loyerMin': filtres!.loyerMin.toString(),
        if (filtres?.loyerMax != null) 'loyerMax': filtres!.loyerMax.toString(),
        if (filtres?.avanceMax != null) 'avanceMax': filtres!.avanceMax.toString(),
        if (filtres?.meuble != null) 'meuble': filtres!.meuble.toString(),
        if (filtres?.nbPieces != null) 'nbPieces': filtres!.nbPieces.toString(),
      });

      final List list = response.data['data'];
      return list.map((json) => PropertyModel.fromJson(json)).toList();
    } catch (e) {
      // Données de secours de démonstration (offline)
      return _initialProperties;
    }
  }

  /// ❤️ Récupérer les IDs des annonces favorites de l'utilisateur connecté (/moi/favoris)
  /// Renvoie `null` (au lieu de liste vide) si l'appel échoue (déconnecté / hors-ligne),
  /// pour que l'appelant sache qu'il doit garder le cache local plutôt que le vider.
  Future<List<String>?> fetchFavoriIds() async {
    try {
      final response = await _dio.get('/moi/favoris');
      final List list = response.data;
      return list.map((json) => json['id'].toString()).toList();
    } catch (_) {
      return null;
    }
  }

  /// ❤️ Ajouter une annonce aux favoris côté serveur
  Future<bool> addFavori(String annonceId) async {
    try {
      await _dio.post('/annonces/$annonceId/favori');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 💔 Retirer une annonce des favoris côté serveur
  Future<bool> removeFavori(String annonceId) async {
    try {
      await _dio.delete('/annonces/$annonceId/favori');
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Fournisseur Riverpod pour le Repository d'annonces
final propertiesRepositoryProvider = Provider((ref) => PropertiesRepository());

// Données de secours offline initiales
final List<PropertyModel> _initialProperties = [
  PropertyModel(
    id: 'prop-001',
    reference: 'DLA-BM-00123',
    titre: 'Studio Moderne Climatisé avec Balcon',
    description: 'Magnifique studio moderne, entièrement carrelé avec eau courante et compteur ENEO individuel.',
    loyerMensuel: 65000,
    chargesMensuelles: 5000,
    chargesIncluses: true,
    avanceMois: 3,
    cautionMois: 1,
    typeBien: 'STUDIO',
    ville: 'Douala',
    quartier: 'Bonamoussadi',
    pointRepere: 'Carrefour Camico',
    photos: [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
    ],
    isVerified: true,
    isAvailable: true,
    publishedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  PropertyModel(
    id: 'prop-002',
    reference: 'DLA-MK-00456',
    titre: 'Appartement 2 Chambres Salon Makepe',
    description: 'Grand appartement 2 chambres, 2 douches, cuisine spacieuse, gardien 24h/24.',
    loyerMensuel: 120000,
    chargesMensuelles: 10000,
    chargesIncluses: false,
    avanceMois: 6,
    cautionMois: 2,
    typeBien: 'APPARTEMENT',
    ville: 'Douala',
    quartier: 'Makèpè',
    pointRepere: 'Station Total Makepe',
    photos: [
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
    ],
    isVerified: true,
    isAvailable: true,
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

class PropertiesNotifier extends StateNotifier<List<PropertyModel>> {
  final PropertiesRepository _repository;
  bool _loading = false;

  PropertiesNotifier(this._repository) : super(_initialProperties) {
    refresh();
  }

  bool get isLoading => _loading;

  /// Recharge le catalogue depuis l'API. `fetchAnnonces` renvoie soit les vrais
  /// résultats (potentiellement une liste vide si la recherche ne correspond à
  /// rien), soit les données de secours locales en cas d'échec réseau — dans
  /// les deux cas c'est l'état à afficher, pas de filtrage supplémentaire ici.
  Future<void> refresh({String? villeSlug, String? quartierSlug, String? type, RechercheFiltres? filtres}) async {
    _loading = true;
    final data = await _repository.fetchAnnonces(
      villeSlug: villeSlug,
      quartierSlug: quartierSlug,
      type: type,
      filtres: filtres,
    );
    _loading = false;
    state = data;
  }

  void addProperty(PropertyModel newProperty) {
    state = [newProperty, ...state];
  }

  void markAsRented(String propertyId) {
    state = state.map((p) {
      if (p.id == propertyId) {
        return PropertyModel(
          id: p.id,
          reference: p.reference,
          titre: p.titre,
          description: p.description,
          loyerMensuel: p.loyerMensuel,
          chargesMensuelles: p.chargesMensuelles,
          chargesIncluses: p.chargesIncluses,
          avanceMois: p.avanceMois,
          cautionMois: p.cautionMois,
          typeBien: p.typeBien,
          ville: p.ville,
          quartier: p.quartier,
          pointRepere: p.pointRepere,
          photos: p.photos,
          isVerified: p.isVerified,
          isAvailable: false,
          publishedAt: p.publishedAt,
        );
      }
      return p;
    }).toList();
  }
}

// Provider d'annonces dynamique
final propertiesProvider = StateNotifierProvider<PropertiesNotifier, List<PropertyModel>>((ref) {
  return PropertiesNotifier(ref.watch(propertiesRepositoryProvider));
});

/// Gère les favoris réels de l'utilisateur : synchronisés avec l'API
/// (`/moi/favoris`, `POST`/`DELETE /annonces/:id/favori`) et mis en cache
/// localement (shared_preferences) pour rester visibles hors-ligne.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'favori_annonce_ids';

  final PropertiesRepository _repository;

  FavoritesNotifier(this._repository) : super(<String>{}) {
    _loadFromCache();
    refresh();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey);
    if (ids != null) {
      state = ids.toSet();
    }
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }

  /// Recharge la liste depuis l'API. Ne fait rien si l'appel échoue
  /// (utilisateur non connecté ou hors-ligne) : le cache local reste affiché.
  Future<void> refresh() async {
    final ids = await _repository.fetchFavoriIds();
    if (ids != null) {
      state = ids.toSet();
      await _saveToCache();
    }
  }

  bool isFavori(String annonceId) => state.contains(annonceId);

  /// Bascule un favori avec mise à jour optimiste, annulée si l'appel API échoue.
  Future<void> toggle(String annonceId) async {
    final wasFavori = state.contains(annonceId);
    state = wasFavori ? ({...state}..remove(annonceId)) : ({...state}..add(annonceId));
    await _saveToCache();

    final success = wasFavori
        ? await _repository.removeFavori(annonceId)
        : await _repository.addFavori(annonceId);

    if (!success) {
      state = wasFavori ? ({...state}..add(annonceId)) : ({...state}..remove(annonceId));
      await _saveToCache();
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(propertiesRepositoryProvider));
});

// Provider des villes ouvertes
final villesListProvider = FutureProvider<List<VilleOption>>((ref) async {
  final repo = ref.watch(propertiesRepositoryProvider);
  return repo.fetchVilles();
});

// Provider de la ville actuellement sélectionnée pour filtrer le catalogue.
// `null` = toutes les villes ouvertes.
final selectedVilleProvider = StateProvider<VilleOption?>((ref) => null);

// Filtres de recherche étendus (budget, avance, meublé, nb pièces) actuellement actifs.
final searchFiltersProvider = StateProvider<RechercheFiltres>((ref) => const RechercheFiltres());

// Provider de bascule du mode Économie de Data (3G)
final dataSaverModeProvider = StateProvider<bool>((ref) => false);

