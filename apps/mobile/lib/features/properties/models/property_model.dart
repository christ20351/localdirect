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

  /// L'API (`AnnoncesService.formatAnnonceResponse`) renvoie une forme imbriquée :
  /// `{ id, titre, description, finances: {...}, bien: {...}, createdAt }`.
  /// Ce parsing doit rester synchronisé avec cette forme exacte.
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final finances = json['finances'] as Map<String, dynamic>? ?? const {};
    final bien = json['bien'] as Map<String, dynamic>? ?? const {};
    final statut = bien['statut'] as String?;

    return PropertyModel(
      id: json['id'] as String,
      reference: bien['reference'] as String? ?? '',
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      loyerMensuel: (finances['loyerMensuelXAF'] as num? ?? 0).toInt(),
      chargesMensuelles: (finances['chargesMensuellesXAF'] as num? ?? 0).toInt(),
      chargesIncluses: finances['chargesIncluses'] as bool? ?? false,
      avanceMois: finances['avanceMois'] as int? ?? 2,
      cautionMois: finances['cautionMois'] as int? ?? 1,
      typeBien: bien['type'] as String? ?? 'STUDIO',
      ville: bien['ville'] as String? ?? '',
      quartier: bien['quartier'] as String? ?? '',
      pointRepere: bien['pointRepere'] as String? ?? '',
      photos: (bien['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      // Le catalogue public (`GET /annonces`) ne renvoie que des biens DISPONIBLE :
      // en l'absence de statut explicite, on considère l'annonce vérifiée/disponible.
      isVerified: statut == null || statut == 'DISPONIBLE',
      isAvailable: statut == null || statut == 'DISPONIBLE',
      publishedAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'finances': {
        'loyerMensuelXAF': loyerMensuel,
        'chargesMensuellesXAF': chargesMensuelles,
        'chargesIncluses': chargesIncluses,
        'avanceMois': avanceMois,
        'cautionMois': cautionMois,
      },
      'bien': {
        'reference': reference,
        'type': typeBien,
        'ville': ville,
        'quartier': quartier,
        'pointRepere': pointRepere,
        'photos': photos,
        'statut': isAvailable ? 'DISPONIBLE' : 'LOUE',
      },
      'createdAt': publishedAt.toIso8601String(),
    };
  }
}
