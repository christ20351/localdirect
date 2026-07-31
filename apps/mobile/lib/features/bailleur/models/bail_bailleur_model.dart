class BailFiscal {
  final int loyerBrutXAF;
  final double tauxPrecompte;
  final int precompteXAF;
  final int netBailleurXAF;

  const BailFiscal({
    required this.loyerBrutXAF,
    required this.tauxPrecompte,
    required this.precompteXAF,
    required this.netBailleurXAF,
  });

  factory BailFiscal.fromJson(Map<String, dynamic> json) {
    return BailFiscal(
      loyerBrutXAF: (json['loyerBrutXAF'] as num?)?.toInt() ?? 0,
      tauxPrecompte: (json['tauxPrecompte'] as num?)?.toDouble() ?? 10.0,
      precompteXAF: (json['precompteXAF'] as num?)?.toInt() ?? 0,
      netBailleurXAF: (json['netBailleurXAF'] as num?)?.toInt() ?? 0,
    );
  }
}

class BailBailleurModel {
  final String id;
  final String reference;
  final String statut;
  final DateTime? dateDebut;
  final BailFiscal fiscal;
  final String? ville;
  final String? quartier;

  const BailBailleurModel({
    required this.id,
    required this.reference,
    required this.statut,
    this.dateDebut,
    required this.fiscal,
    this.ville,
    this.quartier,
  });

  factory BailBailleurModel.fromJson(Map<String, dynamic> json) {
    final bien = json['bien'] as Map<String, dynamic>?;
    return BailBailleurModel(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
      dateDebut: json['dateDebut'] != null ? DateTime.tryParse(json['dateDebut'] as String) : null,
      fiscal: BailFiscal.fromJson(json['fiscal'] as Map<String, dynamic>? ?? const {}),
      ville: bien?['ville'] as String?,
      quartier: bien?['quartier'] as String?,
    );
  }
}
