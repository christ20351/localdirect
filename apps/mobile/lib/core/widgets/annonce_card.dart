import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../l10n/app_localizations.dart';
import '../../features/properties/models/property_model.dart';

/// Carte d'annonce réutilisable : image hero avec dégradé + titre/quartier
/// superposés, badge favori flottant, puis bandeau prix + CTA en dessous.
/// Utilisée par le catalogue (et potentiellement d'autres listes plus tard).
class AnnonceCard extends StatelessWidget {
  final PropertyModel item;
  final bool isDataSaver;
  final bool isFavori;
  final VoidCallback onTap;
  final VoidCallback onFavoriToggle;

  const AnnonceCard({
    super.key,
    required this.item,
    required this.isDataSaver,
    required this.isFavori,
    required this.onTap,
    required this.onFavoriToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showPhoto = !isDataSaver && item.photos.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (showPhoto)
                    (item.photos.first.startsWith('http')
                        ? Image.network(
                            item.photos.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(color: Theme.of(context).colorScheme.surface);
                            },
                            errorBuilder: (context, error, stack) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                            ),
                          )
                        : Image.file(
                            File(item.photos.first.replaceAll('file://', '')),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                            ),
                          ))
                  else
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      alignment: Alignment.center,
                      child: Icon(
                        isDataSaver ? Icons.data_saver_off : Icons.image_outlined,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),

                  // Dégradé bas pour la lisibilité du titre superposé
                  if (showPhoto)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                  // Badge "Visite Garantie"
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(context.tr('card_verified_visit'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Favori
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavori ? Icons.favorite : Icons.favorite_border,
                          color: isFavori ? AppColors.crimson : Colors.white,
                          size: 20,
                        ),
                        onPressed: onFavoriToggle,
                      ),
                    ),
                  ),

                  // Titre + quartier superposés
                  if (showPhoto)
                    Positioned(
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.white70),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${item.quartier} — ${item.pointRepere}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showPhoto) ...[
                    Text(item.titre, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text('${item.quartier} — ${item.pointRepere}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    CurrencyFormatter.formatXAF(item.loyerMensuel),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Text(context.tr('card_per_month_short'), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                            Text(
                              '${context.tr('card_advance_label')} ${item.avanceMois} ${context.tr('card_month_abbrev')} · '
                              '${context.tr('card_deposit_label')} ${item.cautionMois} ${context.tr('card_month_abbrev')}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(item.typeBien),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
