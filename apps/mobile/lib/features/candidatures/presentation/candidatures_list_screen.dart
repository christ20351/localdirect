import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/candidature_model.dart';
import 'candidatures_provider.dart';

class CandidaturesListScreen extends ConsumerWidget {
  const CandidaturesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatures = ref.watch(candidaturesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('candidatures_list_title'))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(candidaturesProvider.notifier).refresh(),
        child: candidatures.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('candidatures_empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: candidatures.length,
                itemBuilder: (context, index) => _buildCandidatureCard(context, candidatures[index]),
              ),
      ),
    );
  }

  Widget _buildCandidatureCard(BuildContext context, CandidatureModel c) {
    final statutColor = switch (c.statut) {
      CandidatureStatus.acceptee => Colors.green,
      CandidatureStatus.refusee || CandidatureStatus.retiree => AppColors.crimson,
      CandidatureStatus.enExamen => AppColors.accentGold,
      _ => Colors.grey,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(context.tr(c.statut.labelKey), style: const TextStyle(fontSize: 11)),
              backgroundColor: statutColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: statutColor, fontWeight: FontWeight.bold),
              side: BorderSide.none,
            ),
            const SizedBox(height: 12),
            Text(c.annonce?.titre ?? context.tr('visit_default_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${c.annonce?.ville ?? ""} — ${c.annonce?.quartier ?? ""} · ${CurrencyFormatter.formatXAF(c.annonce?.loyerMensuelXAF ?? 0)}${context.tr('favorites_per_month')}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            if (c.motifRefus != null) ...[
              const SizedBox(height: 8),
              Text('${context.tr('candidature_refusal_reason')}${c.motifRefus}', style: const TextStyle(color: AppColors.crimson, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
