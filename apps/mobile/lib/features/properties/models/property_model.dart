class PropertyModel {
  final String id;
  final String reference;
  final String titre;
  final String description;
  final int loyerMensuel; // XAF
  final int chargesMensuelles;
  final bool chargesIncluses;
  final int avanceMois; // 2 à 6 mois
  final int cautionMois; // 1 à 2 mois
  final String typeBien; // STUDIO, APPARTEMENT, CHAMBRE_MODERNE...
  final String ville;
  final String quartier;
  final String pointRepere;
  final List<String> photos;
  final bool isVerified;
  final bool isAvailable;
  final DateTime publishedAt;

  PropertyModel({
    required this.id,
    required this.reference,
    required this.titre,
    required this.description,
    required this.loyerMensuel,
    required this.chargesMensuelles,
    required this.chargesIncluses,
    required this.avanceMois,
    required this.cautionMois,
    required this.typeBien,
    required this.ville,
    required this.quartier,
    required this.pointRepere,
    required this.photos,
    required this.isVerified,
    required this.isAvailable,
    required this.publishedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      reference: json['reference'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      loyerMensuel: (json['loyer_mensuel'] as num).toInt(),
      chargesMensuelles: (json['charges_mensuelles'] as num? ?? 0).toInt(),
      chargesIncluses: json['charges_incluses'] as bool? ?? false,
      avanceMois: json['avance_mois'] as int? ?? 2,
      cautionMois: json['caution_mois'] as int? ?? 1,
      typeBien: json['type'] as String? ?? 'STUDIO',
      ville: json['ville'] as String? ?? 'Douala',
      quartier: json['quartier'] as String? ?? 'Bonamoussadi',
      pointRepere: json['point_repere'] as String? ?? 'Carrefour Kotto',
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isVerified: json['statut'] == 'DISPONIBLE',
      isAvailable: json['is_available'] as bool? ?? true,
      publishedAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'titre': titre,
      'description': description,
      'loyer_mensuel': loyerMensuel,
      'charges_mensuelles': chargesMensuelles,
      'charges_incluses': chargesIncluses,
      'avance_mois': avanceMois,
      'caution_mois': cautionMois,
      'type': typeBien,
      'ville': ville,
      'quartier': quartier,
      'point_repere': pointRepere,
      'photos': photos,
      'is_available': isAvailable,
      'created_at': publishedAt.toIso8601String(),
    };
  }
}
