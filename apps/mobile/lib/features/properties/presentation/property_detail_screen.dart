import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'property_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../visits/presentation/visites_provider.dart';
import '../../visits/models/visit_model.dart';
import '../../candidatures/presentation/candidatures_provider.dart';
import '../../candidatures/presentation/candidature_form_sheet.dart';
import '../../candidatures/models/candidature_model.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final item = properties.firstWhere(
      (element) => element.id == widget.propertyId,
      orElse: () => properties.first,
    );

    final financial = CurrencyFormatter.calculateUpfrontCost(
      loyerMensuel: item.loyerMensuel,
      avanceMois: item.avanceMois,
      cautionMois: item.cautionMois,
    );

    final favoris = ref.watch(favoritesProvider);
    final isFavori = favoris.contains(item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.titre),
        actions: [
          IconButton(
            icon: Icon(
              isFavori ? Icons.favorite : Icons.favorite_border,
              color: isFavori ? AppColors.crimson : null,
            ),
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(item.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Photo
            if (item.photos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: item.photos.first.startsWith('http')
                      ? Image.network(item.photos.first, fit: BoxFit.cover)
                      : Image.file(File(item.photos.first.replaceAll('file://', '')), fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),

            // Header info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('${item.ville} — ${item.quartier}'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${context.tr('detail_reference_prefix')}${item.reference}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              item.titre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),

            const SizedBox(height: 24),
            // Financial Breakdown Card (Specific Cameroon: Avance + Caution + Loyer)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('detail_financial_title'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildCostRow(context.tr('detail_rent'), CurrencyFormatter.formatXAF(item.loyerMensuel)),
                    _buildCostRow(
                      '${context.tr('detail_advance')} (${item.avanceMois} ${context.tr('filters_month_unit')})',
                      CurrencyFormatter.formatXAF(financial['montantAvance']),
                    ),
                    _buildCostRow(
                      '${context.tr('detail_deposit')} (${item.cautionMois} ${context.tr('filters_month_unit')})',
                      CurrencyFormatter.formatXAF(financial['montantCaution']),
                    ),
                    const Divider(height: 20),
                    _buildCostRow(
                      context.tr('detail_total_move_in'),
                      CurrencyFormatter.formatXAF(financial['totalInitial']),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fuzzy position notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppColors.accentGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('detail_position_hidden'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CTA visite
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.phone_android),
                label: Text('${context.tr('detail_book_visit')} (${CurrencyFormatter.formatXAF(financial['fraisVisite'])} MoMo)'),
                onPressed: _demarrerReservation,
              ),
            ),

            const SizedBox(height: 12),
            _buildCandidatureSection(item.id),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatureSection(String annonceId) {
    final candidatures = ref.watch(candidaturesProvider);
    CandidatureModel? candidature;
    try {
      candidature = candidatures.firstWhere((c) => c.annonceId == annonceId);
    } catch (_) {
      candidature = null;
    }

    if (candidature != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_shared, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${context.tr('detail_candidature_sent')}${context.tr(candidature.statut.labelKey)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
        icon: const Icon(Icons.folder_shared_outlined, color: AppColors.primary),
        label: Text(context.tr('detail_candidature_submit'), style: const TextStyle(color: AppColors.primary)),
        onPressed: () => _ouvrirFormulaireCandidature(annonceId),
      ),
    );
  }

  Future<void> _ouvrirFormulaireCandidature(String annonceId) async {
    final token = await ref.read(authRepositoryProvider).getAccessToken();
    if (!mounted) return;

    if (token == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('detail_login_required_title')),
          content: Text(context.tr('detail_login_required_candidature')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/auth/login');
              },
              child: Text(context.tr('detail_login_button')),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CandidatureFormSheet(annonceId: annonceId),
    );
  }

  Widget _buildCostRow(String title, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            amount,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : null,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _demarrerReservation() async {
    final token = await ref.read(authRepositoryProvider).getAccessToken();
    if (!mounted) return;

    if (token == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('detail_login_required_title')),
          content: Text(context.tr('detail_login_required_visit')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/auth/login');
              },
              child: Text(context.tr('detail_login_button')),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    _showMoMoModal(context);
  }

  void _showMoMoModal(BuildContext context) {
    final numeroCtrl = TextEditingController();
    String methode = 'MTN_MOMO';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('detail_momo_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('detail_momo_subtitle'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'MTN_MOMO', label: Text('MTN MoMo')),
                  ButtonSegment(value: 'ORANGE_MONEY', label: Text('Orange Money')),
                ],
                selected: {methode},
                onSelectionChanged: isSubmitting
                    ? null
                    : (val) => setModalState(() => methode = val.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numeroCtrl,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: context.tr('detail_momo_number_label'),
                  prefixText: '+237 ',
                  hintText: '6XXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final numero = numeroCtrl.text.trim();
                          if (numero.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(context.tr('detail_momo_number_required'))),
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          await _reserverEtPayer(
                            annonceId: widget.propertyId,
                            methode: methode,
                            numero: numero.startsWith('+237') ? numero : '+237$numero',
                            modalContext: ctx,
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.tr('detail_momo_submit')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reserverEtPayer({
    required String annonceId,
    required String methode,
    required String numero,
    required BuildContext modalContext,
  }) async {
    // Traductions captées avant les `await` pour ne jamais lire `context` après une coupure asynchrone.
    final erreurVisite = context.tr('detail_visit_error');
    final succesVisite = context.tr('detail_visit_success');
    final visiteEnAttente = context.tr('detail_visit_pending');
    final paiementEchoue = context.tr('detail_payment_failed');

    final visitesRepo = ref.read(visitesRepositoryProvider);

    final demande = await visitesRepo.demanderVisite(annonceId);
    if (demande['success'] != true) {
      if (modalContext.mounted) Navigator.pop(modalContext);
      _showResultSnackBar(demande['message'] ?? erreurVisite, isError: true);
      return;
    }

    final visiteId = (demande['visite'] as VisitModel).id;
    final paiement = await visitesRepo.payerVisite(visiteId, methode: methode, numero: numero);

    if (modalContext.mounted) Navigator.pop(modalContext);

    if (paiement['success'] == true && paiement['statutPaiement'] == 'REUSSI') {
      ref.read(visitesProvider.notifier).refresh();
      _showResultSnackBar(succesVisite, isError: false);
    } else if (paiement['success'] == true) {
      ref.read(visitesProvider.notifier).refresh();
      _showResultSnackBar(visiteEnAttente, isError: false);
    } else {
      _showResultSnackBar(paiement['message'] ?? paiementEchoue, isError: true);
    }
  }

  void _showResultSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.crimson : AppColors.primary,
      ),
    );
  }
}
