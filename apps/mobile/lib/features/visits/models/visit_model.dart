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
}

extension VisitStatusX on VisitStatus {
  String get label {
    switch (this) {
      case VisitStatus.demandee:
        return 'En attente de paiement MoMo';
      case VisitStatus.payee:
        return 'Visite Payée & Garantie';
      case VisitStatus.planifiee:
        return 'Créneau Confirmé avec l\'Agent';
      case VisitStatus.checkIn:
        return 'Agent Présent sur le Terrain (GPS)';
      case VisitStatus.realisee:
        return 'Visite Effectuée';
      case VisitStatus.confirmee:
        return 'Visite Confirmée par le Locataire';
      case VisitStatus.contestee:
        return 'Contestée (Litige)';
      case VisitStatus.annulee:
        return 'Annulée';
      case VisitStatus.remboursee:
        return 'Frais Remboursés via MoMo';
    }
  }
}

class VisitModel {
  final String id;
  final String propertyId;
  final String tenantId;
  final String? agentId;
  final VisitStatus status;
  final int feeAmountXAF;
  final String? confirmationCode; // Code 4 chiffres
  final DateTime? scheduledTime;
  final DateTime createdAt;

  VisitModel({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    this.agentId,
    required this.status,
    required this.feeAmountXAF,
    this.confirmationCode,
    this.scheduledTime,
    required this.createdAt,
  });
}
