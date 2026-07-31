import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/bien_model.dart';
import '../models/bail_bailleur_model.dart';
import '../../candidatures/models/candidature_model.dart';
import 'bailleur_provider.dart';

class BailleurHomeScreen extends ConsumerStatefulWidget {
  const BailleurHomeScreen({super.key});

  @override
  ConsumerState<BailleurHomeScreen> createState() => _BailleurHomeScreenState();
}

class _BailleurHomeScreenState extends ConsumerState<BailleurHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(mesBiensProvider.notifier).refresh(),
      ref.read(candidaturesRecuesProvider.notifier).refresh(),
      ref.read(mesBauxBailleurProvider.notifier).refresh(),
    ]);
  }

  void _editerBien(BienModel bien) {
    context.push('/bailleur/ajouter-bien', extra: bien);
  }

  Future<void> _marquerLoue(BienModel bien) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('bailleur_bien_mark_rented')),
        content: Text(context.tr('bailleur_bien_mark_rented_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('common_cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('common_confirm'))),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final success = await ref.read(bailleurRepositoryProvider).marquerLoue(bien.id);
    if (!mounted) return;
    if (success) {
      ref.read(mesBiensProvider.notifier).refresh();
    }
  }

  Future<void> _deciderCandidature(CandidatureModel candidature, {required bool accepter}) async {
    String? motif;
    if (!accepter) {
      final motifCtrl = TextEditingController();
      final confirme = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('bailleur_candidature_refuse_title')),
          content: TextField(
            controller: motifCtrl,
            maxLines: 2,
            decoration: InputDecoration(hintText: context.tr('bailleur_candidature_refuse_hint')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('common_cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr('bailleur_candidature_refuse')),
            ),
          ],
        ),
      );
      if (confirme != true || !mounted) return;
      motif = motifCtrl.text.trim();
    }

    final result = await ref.read(bailleurRepositoryProvider).deciderCandidature(candidature.id, accepter: accepter, motif: motif);
    if (!mounted) return;

    if (result['success'] == true) {
      ref.read(candidaturesRecuesProvider.notifier).refresh();
      ref.read(mesBiensProvider.notifier).refresh();
      ref.read(mesBauxBailleurProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepter ? context.tr('bailleur_candidature_accepted_snackbar') : context.tr('bailleur_candidature_refused_snackbar')),
          backgroundColor: accepter ? AppColors.primary : null,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? context.tr('bailleur_candidature_decision_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('bailleur_space_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('bailleur_tab_biens')),
            Tab(text: context.tr('bailleur_tab_candidatures')),
            Tab(text: context.tr('bailleur_tab_baux')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBiensTab(context),
          _buildCandidaturesTab(context),
          _buildBauxTab(context),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/bailleur/ajouter-bien'),
              icon: const Icon(Icons.add),
              label: Text(context.tr('bailleur_add_bien')),
            )
          : null,
    );
  }

  Widget _buildBiensTab(BuildContext context) {
    final biens = ref.watch(mesBiensProvider);
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: biens.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              children: [
                Icon(Icons.villa_outlined, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(context.tr('bailleur_biens_empty'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: biens.length,
              itemBuilder: (context, index) => _buildBienCard(context, biens[index]),
            ),
    );
  }

  Widget _buildBienCard(BuildContext context, BienModel bien) {
    final statutColor = switch (bien.statut) {
      BienStatus.disponible => Colors.green,
      BienStatus.reserve => AppColors.accentGold,
      BienStatus.loue => AppColors.primary,
      BienStatus.rejete || BienStatus.suspendu || BienStatus.expire => AppColors.crimson,
      _ => Colors.grey,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(context.tr(bien.statut.labelKey), style: const TextStyle(fontSize: 11)),
                  backgroundColor: statutColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statutColor, fontWeight: FontWeight.bold),
                  side: BorderSide.none,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editerBien(bien);
                    if (value == 'louer') _marquerLoue(bien);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'edit', child: Text(context.tr('bailleur_bien_edit'))),
                    if (bien.statut != BienStatus.loue)
                      PopupMenuItem(value: 'louer', child: Text(context.tr('bailleur_bien_mark_rented'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bien.titre ?? bien.reference, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${bien.ville ?? ""} — ${bien.quartier ?? ""}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            if (bien.loyerMensuelXAF != null) ...[
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatXAF(bien.loyerMensuelXAF!),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
            if (bien.motifRejet != null) ...[
              const SizedBox(height: 8),
              Text('${context.tr('bailleur_bien_rejection_reason')}${bien.motifRejet}', style: const TextStyle(color: AppColors.crimson, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCandidaturesTab(BuildContext context) {
    final candidatures = ref.watch(candidaturesRecuesProvider);
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: candidatures.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              children: [
                Icon(Icons.folder_shared_outlined, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(context.tr('bailleur_candidatures_empty'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: candidatures.length,
              itemBuilder: (context, index) => _buildCandidatureCard(context, candidatures[index]),
            ),
    );
  }

  Widget _buildCandidatureCard(BuildContext context, CandidatureModel c) {
    final enAttente = c.statut == CandidatureStatus.soumise || c.statut == CandidatureStatus.enExamen;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.locataire?.nomComplet ?? '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(c.locataire?.telephone ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 6),
            Text(c.annonce?.titre ?? '', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            if (c.revenuDeclareXAF != null) Text('${context.tr('bailleur_candidature_income')}${CurrencyFormatter.formatXAF(c.revenuDeclareXAF!)}', style: const TextStyle(fontSize: 12)),
            if (c.nbOccupants != null) Text('${context.tr('bailleur_candidature_occupants')}${c.nbOccupants}', style: const TextStyle(fontSize: 12)),
            if (c.locataire != null) Text('${context.tr('bailleur_candidature_kyc')}${c.locataire!.statutKyc}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Chip(
              label: Text(context.tr(c.statut.labelKey), style: const TextStyle(fontSize: 11)),
              backgroundColor: (enAttente ? AppColors.accentGold : (c.statut == CandidatureStatus.acceptee ? Colors.green : AppColors.crimson)).withValues(alpha: 0.15),
              labelStyle: TextStyle(color: enAttente ? AppColors.accentGold : (c.statut == CandidatureStatus.acceptee ? Colors.green : AppColors.crimson), fontWeight: FontWeight.bold),
              side: BorderSide.none,
            ),
            if (enAttente) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.crimson, side: const BorderSide(color: AppColors.crimson)),
                      onPressed: () => _deciderCandidature(c, accepter: false),
                      child: Text(context.tr('bailleur_candidature_refuse')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _deciderCandidature(c, accepter: true),
                      child: Text(context.tr('bailleur_candidature_accept')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBauxTab(BuildContext context) {
    final baux = ref.watch(mesBauxBailleurProvider);
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: baux.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              children: [
                Icon(Icons.description_outlined, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(context.tr('bailleur_baux_empty'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: baux.length,
              itemBuilder: (context, index) => _buildBailCard(context, baux[index]),
            ),
    );
  }

  Widget _buildBailCard(BuildContext context, BailBailleurModel bail) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${context.tr('bailleur_bail_reference')} ${bail.reference}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(bail.statut, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${bail.ville ?? ""} — ${bail.quartier ?? ""}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const Divider(height: 24),
            _fiscalRow(context, context.tr('bailleur_bail_gross_rent'), bail.fiscal.loyerBrutXAF),
            _fiscalRow(context, '${context.tr('bailleur_bail_precompte')} (${bail.fiscal.tauxPrecompte.toStringAsFixed(0)}%)', -bail.fiscal.precompteXAF),
            const Divider(height: 16),
            _fiscalRow(context, context.tr('bailleur_bail_net'), bail.fiscal.netBailleurXAF, emphasize: true),
          ],
        ),
      ),
    );
  }

  Widget _fiscalRow(BuildContext context, String label, int amount, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: emphasize ? 14 : 13, fontWeight: emphasize ? FontWeight.bold : FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${amount < 0 ? '-' : ''}${CurrencyFormatter.formatXAF(amount.abs())}',
            style: TextStyle(
              fontSize: emphasize ? 14 : 13,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              color: emphasize ? AppColors.primary : (amount < 0 ? AppColors.crimson : null),
            ),
          ),
        ],
      ),
    );
  }
}
