import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/alerte_model.dart';
import 'alertes_provider.dart';

/// Liste des alertes de recherche enregistrées. Honnête sur ce que fait vraiment
/// la fonctionnalité aujourd'hui : pas de notification push/SMS envoyée — il faut
/// revenir consulter cet écran pour voir le nombre de nouvelles annonces correspondantes.
class AlertesListScreen extends ConsumerWidget {
  const AlertesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertes = ref.watch(alertesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('alertes_title'))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alertesProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accentGold, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.tr('alertes_no_push_notice'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (alertes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('alertes_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              ...alertes.map((a) => _buildAlerteCard(context, ref, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerteCard(BuildContext context, WidgetRef ref, AlerteModel alerte) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: Badge(
          isLabelVisible: alerte.nouvellesCorrespondances > 0,
          label: Text('${alerte.nouvellesCorrespondances}'),
          child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
        ),
        title: Text(alerte.resume ?? context.tr('alertes_all_cities_criteria')),
        subtitle: alerte.nouvellesCorrespondances > 0
            ? Text('${alerte.nouvellesCorrespondances}${context.tr('alertes_new_count')}', style: const TextStyle(color: AppColors.primary, fontSize: 12))
            : Text(context.tr('alertes_nothing_new'), style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.crimson),
          onPressed: () async {
            await ref.read(alertesRepositoryProvider).supprimerAlerte(alerte.id);
            ref.read(alertesProvider.notifier).refresh();
          },
        ),
      ),
    );
  }
}
