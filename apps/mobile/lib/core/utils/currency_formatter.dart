import 'package:intl/intl.dart';

/// Formateur monétaire strict pour le FCFA (XAF).
/// Respecte la décision structurante D10 du projet LocaDirect CM :
/// "Montants en entier XAF, jamais en flottant (le FCFA n'a pas de subdivision)".
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'fr_CM',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  /// Formate un montant entier en FCFA (ex: 150000 -> "150 000 FCFA")
  static String formatXAF(int amount) {
    return _formatter.format(amount).replaceAll('\u00A0', ' ');
  }

  /// Formate le loyer mensuel et les charges séparément
  static String formatRentSummary(int loyerMensuel, int chargesMensuelles, {bool chargesIncluses = false}) {
    final loyerFormatted = formatXAF(loyerMensuel);
    if (chargesMensuelles <= 0) {
      return loyerFormatted;
    }
    final chargesFormatted = formatXAF(chargesMensuelles);
    if (chargesIncluses) {
      return '$loyerFormatted / mois (charges incluses : $chargesFormatted)';
    }
    return '$loyerFormatted + $chargesFormatted charges / mois';
  }

  /// Calcule l'avance et la caution totales
  static Map<String, dynamic> calculateUpfrontCost({
    required int loyerMensuel,
    required int avanceMois,
    required int cautionMois,
    int fraisVisite = 2000,
  }) {
    final int montantAvance = loyerMensuel * avanceMois;
    final int montantCaution = loyerMensuel * cautionMois;
    final int totalInitial = montantAvance + montantCaution;

    return {
      'montantAvance': montantAvance,
      'montantCaution': montantCaution,
      'totalInitial': totalInitial,
      'fraisVisite': fraisVisite,
    };
  }
}
