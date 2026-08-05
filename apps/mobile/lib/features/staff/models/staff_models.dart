import '../../documents/models/document_model.dart';

class StaffDocumentModel {
  final DocumentModel document;
  final String? utilisateurNom;
  final String? utilisateurTelephone;
  final String? bienReference;

  const StaffDocumentModel({
    required this.document,
    this.utilisateurNom,
    this.utilisateurTelephone,
    this.bienReference,
  });

  factory StaffDocumentModel.fromJson(Map<String, dynamic> json) {
    final utilisateur = json['utilisateur'] as Map<String, dynamic>?;
    final bien = json['bien'] as Map<String, dynamic>?;
    return StaffDocumentModel(
      document: DocumentModel.fromJson(json),
      utilisateurNom: utilisateur?['nomComplet'] as String?,
      utilisateurTelephone: utilisateur?['telephone'] as String?,
      bienReference: bien?['reference'] as String?,
    );
  }
}

class StaffBienModel {
  final String id;
  final String reference;
  final String type;
  final String statut;
  final String? titre;
  final String? ville;
  final String? quartier;
  final List<String> photos;
  final int? loyerMensuelXAF;
  final String? bailleurNom;
  final String? bailleurTelephone;
  final String? bailleurTelBrut;
  final String? creeParNom;
  final String? creeParTelephone;
  final List<String> creeParRoles;

  const StaffBienModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.statut,
    this.titre,
    this.ville,
    this.quartier,
    required this.photos,
    this.loyerMensuelXAF,
    this.bailleurNom,
    this.bailleurTelephone,
    this.bailleurTelBrut,
    this.creeParNom,
    this.creeParTelephone,
    required this.creeParRoles,
  });

  factory StaffBienModel.fromJson(Map<String, dynamic> json) {
    final bailleur = json['bailleur'] as Map<String, dynamic>?;
    final creePar = json['creePar'] as Map<String, dynamic>?;
    return StaffBienModel(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      type: json['type'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
      titre: json['titre'] as String?,
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      loyerMensuelXAF: (json['loyerMensuelXAF'] as num?)?.toInt(),
      bailleurNom: bailleur?['nomComplet'] as String?,
      bailleurTelephone: bailleur?['telephone'] as String?,
      bailleurTelBrut: json['bailleurTel'] as String?,
      creeParNom: creePar?['nomComplet'] as String?,
      creeParTelephone: creePar?['telephone'] as String?,
      creeParRoles: (creePar?['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
