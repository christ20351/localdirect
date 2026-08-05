enum BienStatus { brouillon, enVerification, disponible, reserve, loue, suspendu, expire, rejete, inconnu }

extension BienStatusX on BienStatus {
  static BienStatus fromApi(String value) {
    switch (value) {
      case 'BROUILLON':
        return BienStatus.brouillon;
      case 'EN_VERIFICATION':
        return BienStatus.enVerification;
      case 'DISPONIBLE':
        return BienStatus.disponible;
      case 'RESERVE':
        return BienStatus.reserve;
      case 'LOUE':
        return BienStatus.loue;
      case 'SUSPENDU':
        return BienStatus.suspendu;
      case 'EXPIRE':
        return BienStatus.expire;
      case 'REJETE':
        return BienStatus.rejete;
      default:
        return BienStatus.inconnu;
    }
  }

  /// Clé de traduction — résolue au point d'affichage via `context.tr(statut.labelKey)`.
  String get labelKey {
    switch (this) {
      case BienStatus.brouillon:
        return 'bien_statut_brouillon';
      case BienStatus.enVerification:
        return 'bien_statut_en_verification';
      case BienStatus.disponible:
        return 'bien_statut_disponible';
      case BienStatus.reserve:
        return 'bien_statut_reserve';
      case BienStatus.loue:
        return 'bien_statut_loue';
      case BienStatus.suspendu:
        return 'bien_statut_suspendu';
      case BienStatus.expire:
        return 'bien_statut_expire';
      case BienStatus.rejete:
        return 'bien_statut_rejete';
      case BienStatus.inconnu:
        return 'bien_statut_inconnu';
    }
  }
}

class BienModel {
  final String id;
  final String reference;
  final String type;
  final BienStatus statut;
  final String? motifRejet;
  final bool meuble;
  final List<String> equipements;
  final String? ville;
  final String? quartier;
  final List<String> photos;
  final String? annonceId;
  final String? titre;
  final int? loyerMensuelXAF;
  final DateTime? createdAt;
  final String? bailleurTel;
  final String? bailleurWhatsapp;

  const BienModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.statut,
    this.motifRejet,
    required this.meuble,
    required this.equipements,
    this.ville,
    this.quartier,
    required this.photos,
    this.annonceId,
    this.titre,
    this.loyerMensuelXAF,
    this.createdAt,
    this.bailleurTel,
    this.bailleurWhatsapp,
  });

  factory BienModel.fromJson(Map<String, dynamic> json) {
    return BienModel(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      type: json['type'] as String? ?? '',
      statut: BienStatusX.fromApi(json['statut'] as String? ?? ''),
      motifRejet: json['motifRejet'] as String?,
      meuble: json['meuble'] as bool? ?? false,
      equipements: (json['equipements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      annonceId: json['annonceId'] as String?,
      titre: json['titre'] as String?,
      loyerMensuelXAF: (json['loyerMensuelXAF'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      bailleurTel: json['bailleurTel'] as String?,
      bailleurWhatsapp: json['bailleurWhatsapp'] as String?,
    );
  }
}
