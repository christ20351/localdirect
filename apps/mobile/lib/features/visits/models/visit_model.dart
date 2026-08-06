enum VisitStatus {
  demandee,
  payee,
  planifiee,
  checkIn,
  realisee,
  confirmee,
  contestee,
  annulee,
  remboursee,
  noShow,
  inconnue;

  static VisitStatus fromApi(String value) {
    switch (value) {
      case 'DEMANDEE':
        return VisitStatus.demandee;
      case 'PAYEE':
        return VisitStatus.payee;
      case 'PLANIFIEE':
        return VisitStatus.planifiee;
      case 'CHECK_IN':
        return VisitStatus.checkIn;
      case 'REALISEE':
        return VisitStatus.realisee;
      case 'CONFIRMEE':
        return VisitStatus.confirmee;
      case 'CONTESTEE':
        return VisitStatus.contestee;
      case 'ANNULEE':
        return VisitStatus.annulee;
      case 'REMBOURSEE':
        return VisitStatus.remboursee;
      case 'NO_SHOW':
        return VisitStatus.noShow;
      default:
        return VisitStatus.inconnue;
    }
  }
}

extension VisitStatusX on VisitStatus {
  /// Clé de traduction — résolue au point d'affichage via `context.tr(status.labelKey)`
  /// (un modèle Dart n'a pas accès au `BuildContext` pour traduire lui-même).
  String get labelKey {
    switch (this) {
      case VisitStatus.demandee:
        return 'visit_status_demandee';
      case VisitStatus.payee:
        return 'visit_status_payee';
      case VisitStatus.planifiee:
        return 'visit_status_planifiee';
      case VisitStatus.checkIn:
        return 'visit_status_checkin';
      case VisitStatus.realisee:
        return 'visit_status_realisee';
      case VisitStatus.confirmee:
        return 'visit_status_confirmee';
      case VisitStatus.contestee:
        return 'visit_status_contestee';
      case VisitStatus.annulee:
        return 'visit_status_annulee';
      case VisitStatus.remboursee:
        return 'visit_status_remboursee';
      case VisitStatus.noShow:
        return 'visit_status_noshow';
      case VisitStatus.inconnue:
        return 'visit_status_inconnue';
    }
  }

  /// `true` si le locataire peut encore confirmer/contester cette visite (contact
  /// direct avec le bailleur désormais : plus de paiement ni de check-in agent).
  bool get peutEtreClotureeParLocataire => this == VisitStatus.demandee;
}

class VisitAnnonceSummary {
  final String id;
  final String titre;
  final String? ville;
  final String? quartier;
  final String? photo;
  final String? bailleurTel;
  final String? bailleurWhatsapp;

  const VisitAnnonceSummary({
    required this.id,
    required this.titre,
    this.ville,
    this.quartier,
    this.photo,
    this.bailleurTel,
    this.bailleurWhatsapp,
  });

  factory VisitAnnonceSummary.fromJson(Map<String, dynamic> json) {
    return VisitAnnonceSummary(
      id: json['id'] as String,
      titre: json['titre'] as String? ?? '',
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      photo: json['photo'] as String?,
      bailleurTel: json['bailleurTel'] as String?,
      bailleurWhatsapp: json['bailleurWhatsapp'] as String?,
    );
  }
}

class VisitModel {
  final String id;
  final String annonceId;
  final VisitStatus status;
  final String? motifContestation;
  final DateTime? scheduledTime;
  final DateTime? confirmeeLe;
  final DateTime createdAt;
  final VisitAnnonceSummary? annonce;

  const VisitModel({
    required this.id,
    required this.annonceId,
    required this.status,
    this.motifContestation,
    this.scheduledTime,
    this.confirmeeLe,
    required this.createdAt,
    this.annonce,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as String,
      annonceId: json['annonceId'] as String,
      status: VisitStatus.fromApi(json['statut'] as String? ?? ''),
      motifContestation: json['motifContestation'] as String?,
      scheduledTime: json['creneauDebut'] != null ? DateTime.tryParse(json['creneauDebut'] as String) : null,
      confirmeeLe: json['confirmeeLe'] != null ? DateTime.tryParse(json['confirmeeLe'] as String) : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      annonce: json['annonce'] != null ? VisitAnnonceSummary.fromJson(json['annonce'] as Map<String, dynamic>) : null,
    );
  }
}
