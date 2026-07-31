class AlerteModel {
  final String id;
  final String? ville;
  final String? type;
  final int? loyerMax;
  final int nouvellesCorrespondances;

  const AlerteModel({
    required this.id,
    this.ville,
    this.type,
    this.loyerMax,
    required this.nouvellesCorrespondances,
  });

  factory AlerteModel.fromJson(Map<String, dynamic> json) {
    final criteres = json['criteres'] as Map<String, dynamic>? ?? {};
    return AlerteModel(
      id: json['id'] as String,
      ville: criteres['ville'] as String?,
      type: criteres['type'] as String?,
      loyerMax: (criteres['loyerMax'] as num?)?.toInt(),
      nouvellesCorrespondances: (json['nouvellesCorrespondances'] as num?)?.toInt() ?? 0,
    );
  }

  /// `null` si aucun critère n'est défini — l'appelant doit alors afficher un
  /// libellé générique traduit (ex: `context.tr('alertes_all_cities_criteria')`).
  String? get resume {
    final parts = <String>[
      if (ville != null) ville!,
      if (type != null) type!,
      if (loyerMax != null) '≤ $loyerMax FCFA',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
