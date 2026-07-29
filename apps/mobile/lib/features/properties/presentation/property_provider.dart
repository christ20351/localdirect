import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/property_model.dart';
import '../../../core/network/api_client.dart';

// Service API d'accès aux annonces et référentiels géographiques
class PropertiesRepository {
  final Dio _dio = ApiClient.dio;

  /// 🏙️ Récupérer les villes ouvertes depuis l'API NestJS (/api/v1/villes)
  Future<List<String>> fetchVilles() async {
    try {
      final response = await _dio.get('/villes');
      final List data = response.data;
      return data.map((item) => item['nom'].toString()).toList();
    } catch (_) {
      return ['Douala', 'Yaoundé']; // Fallback local si l'API est indisponible
    }
  }

  /// 🔍 Récupérer le catalogue d'annonces dynamiques (/api/v1/annonces)
  Future<List<PropertyModel>> fetchAnnonces({String? ville, String? quartier, String? type}) async {
    try {
      final response = await _dio.get('/annonces', queryParameters: {
        if (ville != null) 'ville': ville.toLowerCase(),
        if (quartier != null) 'quartier': quartier.toLowerCase(),
        if (type != null) 'type': type,
      });

      final List list = response.data['data'];
      return list.map((json) => PropertyModel.fromJson(json)).toList();
    } catch (e) {
      // Données de secours de démonstration (offline)
      return _mockProperties;
    }
  }
}

// Fournisseur Riverpod pour le Repository d'annonces
final propertiesRepositoryProvider = Provider((ref) => PropertiesRepository());

// Données de secours offline
final List<PropertyModel> _mockProperties = [
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
];

// Provider d'annonces (compatibilité synchronous/mock fallback)
final propertiesProvider = Provider<List<PropertyModel>>((ref) {
  return _mockProperties;
});

// Provider des villes ouvertes
final villesListProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(propertiesRepositoryProvider);
  return repo.fetchVilles();
});

// Provider d'état de sélection de la ville
final selectedCityProvider = StateProvider<String>((ref) => 'Douala');

// Provider de bascule du mode Économie de Data (3G)
final dataSaverModeProvider = StateProvider<bool>((ref) => false);

// Provider du rôle utilisateur courant (LOCATAIRE | AGENT | BAILLEUR)
final userRoleProvider = StateProvider<String>((ref) => 'LOCATAIRE');
