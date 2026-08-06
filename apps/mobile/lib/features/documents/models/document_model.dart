enum DocumentStatus { nonSoumis, enAttente, valide, rejete, expire, inconnu }

extension DocumentStatusX on DocumentStatus {
  static DocumentStatus fromApi(String? value) {
    switch (value) {
      case 'NON_SOUMIS':
        return DocumentStatus.nonSoumis;
      case 'EN_ATTENTE':
        return DocumentStatus.enAttente;
      case 'VALIDE':
        return DocumentStatus.valide;
      case 'REJETE':
        return DocumentStatus.rejete;
      case 'EXPIRE':
        return DocumentStatus.expire;
      default:
        return DocumentStatus.inconnu;
    }
  }

  String get labelKey {
    switch (this) {
      case DocumentStatus.nonSoumis:
        return 'document_statut_non_soumis';
      case DocumentStatus.enAttente:
        return 'document_statut_en_attente';
      case DocumentStatus.valide:
        return 'document_statut_valide';
      case DocumentStatus.rejete:
        return 'document_statut_rejete';
      case DocumentStatus.expire:
        return 'document_statut_expire';
      case DocumentStatus.inconnu:
        return 'document_statut_inconnu';
    }
  }
}

class DocumentModel {
  final String id;
  final String? bienId;
  final String type;
  final DocumentStatus statut;
  final String? motifRejet;
  final DateTime? createdAt;

  const DocumentModel({
    required this.id,
    this.bienId,
    required this.type,
    required this.statut,
    this.motifRejet,
    this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      bienId: json['bienId'] as String?,
      type: json['type'] as String? ?? '',
      statut: DocumentStatusX.fromApi(json['statut'] as String?),
      motifRejet: json['motifRejet'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

/// Types de documents acceptés — doit rester synchronisé avec
/// `apps/api/src/documents/types-documents.ts`.
class TypesDocuments {
  static const factureEneoCamwater = 'FACTURE_ENEO_CAMWATER';
  static const cniSelfieBailleur = 'CNI_SELFIE_BAILLEUR';
  static const titrePropriete = 'TITRE_PROPRIETE';
  static const bailOuQuittance = 'BAIL_OU_QUITTANCE';

  static const cniAgentRecto = 'CNI_AGENT_RECTO';
  static const cniAgentVerso = 'CNI_AGENT_VERSO';
  static const selfieAgent = 'SELFIE_AGENT';

  static const preuvePropriete = [factureEneoCamwater, cniSelfieBailleur, titrePropriete, bailOuQuittance];
  static const kycAgent = [cniAgentRecto, cniAgentVerso, selfieAgent];

  static const seuilPreuvePropriete = 2;
  static const seuilKycAgent = 3;

  static String labelKey(String type) => 'document_type_${type.toLowerCase()}';
}
