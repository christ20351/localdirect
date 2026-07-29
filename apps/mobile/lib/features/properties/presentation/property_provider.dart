import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';

final mockProperties = [
  PropertyModel(
    id: 'prop-001',
    reference: 'DLA-BM-00123',
    titre: 'Studio Moderne Climatisé avec Balcon',
    description: 'Magnifique studio moderne, entièrement carrelé avec eau courante (forage) et compteur ENEO individuel. Situé à 2 min du Carrefour Camico.',
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
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
    ],
    isVerified: true,
    isAvailable: true,
    publishedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  PropertyModel(
    id: 'prop-002',
    reference: 'DLA-MK-00456',
    titre: 'Appartement 2 Chambres 2 Douches Spacieux',
    description: 'Grand appartement 2 chambres dans une barrière sécurisée avec gardien. Parking disponible et forage Camwater.',
    loyerMensuel: 140000,
    chargesMensuelles: 10000,
    chargesIncluses: false,
    avanceMois: 6,
    cautionMois: 2,
    typeBien: 'APPARTEMENT',
    ville: 'Douala',
    quartier: 'Makèpè',
    pointRepere: 'Station Total Makèpè',
    photos: [
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
    ],
    isVerified: true,
    isAvailable: true,
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  PropertyModel(
    id: 'prop-003',
    reference: 'YAO-BT-00789',
    titre: 'Chambre Moderne Proche Université',
    description: 'Chambre autonome avec douche interne et coin cuisine. Idéal étudiant ou jeune actif à Biyem-Assi.',
    loyerMensuel: 35000,
    chargesMensuelles: 2000,
    chargesIncluses: true,
    avanceMois: 2,
    cautionMois: 1,
    typeBien: 'CHAMBRE_MODERNE',
    ville: 'Yaoundé',
    quartier: 'Biyem-Assi',
    pointRepere: 'Carrefour Acacias',
    photos: [
      'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80',
    ],
    isVerified: true,
    isAvailable: true,
    publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];

final propertiesProvider = Provider<List<PropertyModel>>((ref) {
  return mockProperties;
});

final selectedCityProvider = StateProvider<String>((ref) => 'Douala');
final dataSaverModeProvider = StateProvider<bool>((ref) => false);
final userRoleProvider = StateProvider<String>((ref) => 'LOCATAIRE'); // LOCATAIRE | AGENT | BAILLEUR
