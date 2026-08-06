enum CandidatureStatus { brouillon, soumise, enExamen, acceptee, refusee, retiree, inconnue }

extension CandidatureStatusX on CandidatureStatus {
  static CandidatureStatus fromApi(String value) {
    switch (value) {
      case 'BROUILLON':
        return CandidatureStatus.brouillon;
      case 'SOUMISE':
        return CandidatureStatus.soumise;
      case 'EN_EXAMEN':
        return CandidatureStatus.enExamen;
      case 'ACCEPTEE':
        return CandidatureStatus.acceptee;
      case 'REFUSEE':
        return CandidatureStatus.refusee;
      case 'RETIREE':
        return CandidatureStatus.retiree;
      default:
        return CandidatureStatus.inconnue;
    }
  }

  /// Clé de traduction — résolue au point d'affichage via `context.tr(status.labelKey)`.
  String get labelKey {
    switch (this) {
      case CandidatureStatus.brouillon:
        return 'candidature_status_brouillon';
      case CandidatureStatus.soumise:
        return 'candidature_status_soumise';
      case CandidatureStatus.enExamen:
        return 'candidature_status_en_examen';
      case CandidatureStatus.acceptee:
        return 'candidature_status_acceptee';
      case CandidatureStatus.refusee:
        return 'candidature_status_refusee';
      case CandidatureStatus.retiree:
        return 'candidature_status_retiree';
      case CandidatureStatus.inconnue:
        return 'candidature_status_inconnue';
    }
  }
}

class CandidatureAnnonceSummary {
  final String id;
  final String titre;
  final String? ville;
  final String? quartier;
  final int loyerMensuelXAF;

  const CandidatureAnnonceSummary({
    required this.id,
    required this.titre,
    this.ville,
    this.quartier,
    required this.loyerMensuelXAF,
  });

  factory CandidatureAnnonceSummary.fromJson(Map<String, dynamic> json) {
    return CandidatureAnnonceSummary(
      id: json['id'] as String,
      titre: json['titre'] as String? ?? '',
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      loyerMensuelXAF: (json['loyerMensuelXAF'] as num?)?.toInt() ?? 0,
    );
  }
}

class CandidatureLocataireSummary {
  final String nomComplet;
  final String telephone;
  final String statutKyc;

  const CandidatureLocataireSummary({required this.nomComplet, required this.telephone, required this.statutKyc});

  factory CandidatureLocataireSummary.fromJson(Map<String, dynamic> json) {
    return CandidatureLocataireSummary(
      nomComplet: json['nomComplet'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      statutKyc: json['statutKyc'] as String? ?? 'NON_SOUMIS',
    );
  }
}

/// Garant rattaché à un dossier de candidature — `GET /moi/candidatures`
/// renvoie ces infos par dossier (le backend persiste `Garant` indépendamment,
/// réutilisable), ce qui permet de préremplir un nouveau formulaire de
/// candidature avec le dernier garant déclaré (voir `CandidatureFormSheet`).
class CandidatureGarantSummary {
  final String nomComplet;
  final String telephone;
  final String? profession;
  final String? lien;

  const CandidatureGarantSummary({required this.nomComplet, required this.telephone, this.profession, this.lien});

  factory CandidatureGarantSummary.fromJson(Map<String, dynamic> json) {
    return CandidatureGarantSummary(
      nomComplet: json['nomComplet'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      profession: json['profession'] as String?,
      lien: json['lien'] as String?,
    );
  }
}

class CandidatureModel {
  final String id;
  final String annonceId;
  final CandidatureStatus statut;
  final int? revenuDeclareXAF;
  final String? sourceRevenu;
  final int? nbOccupants;
  final String? message;
  final String? motifRefus;
  final DateTime? soumiseLe;
  final CandidatureAnnonceSummary? annonce;
  final CandidatureLocataireSummary? locataire;
  final CandidatureGarantSummary? garant;

  const CandidatureModel({
    required this.id,
    required this.annonceId,
    required this.statut,
    this.revenuDeclareXAF,
    this.sourceRevenu,
    this.nbOccupants,
    this.message,
    this.motifRefus,
    this.soumiseLe,
    this.annonce,
    this.locataire,
    this.garant,
  });

  factory CandidatureModel.fromJson(Map<String, dynamic> json) {
    return CandidatureModel(
      id: json['id'] as String,
      annonceId: json['annonceId'] as String,
      statut: CandidatureStatusX.fromApi(json['statut'] as String? ?? ''),
      revenuDeclareXAF: (json['revenuDeclareXAF'] as num?)?.toInt(),
      sourceRevenu: json['sourceRevenu'] as String?,
      nbOccupants: json['nbOccupants'] as int?,
      message: json['message'] as String?,
      motifRefus: json['motifRefus'] as String?,
      soumiseLe: json['soumiseLe'] != null ? DateTime.tryParse(json['soumiseLe'] as String) : null,
      annonce: json['annonce'] != null ? CandidatureAnnonceSummary.fromJson(json['annonce'] as Map<String, dynamic>) : null,
      locataire: json['locataire'] != null ? CandidatureLocataireSummary.fromJson(json['locataire'] as Map<String, dynamic>) : null,
      garant: json['garant'] != null ? CandidatureGarantSummary.fromJson(json['garant'] as Map<String, dynamic>) : null,
    );
  }
}
