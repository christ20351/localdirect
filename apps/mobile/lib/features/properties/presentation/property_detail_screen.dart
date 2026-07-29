import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'property_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final item = properties.firstWhere((element) => element.id == propertyId);

    final financial = CurrencyFormatter.calculateUpfrontCost(
      loyerMensuel: item.loyerMensuel,
      avanceMois: item.avanceMois,
      cautionMois: item.cautionMois,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(item.titre),
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
                  child: Image.network(item.photos.first, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),

            // Header info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('${item.ville} — ${item.quartier}'),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Réf: ${item.reference}',
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
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: AppColors.accentGold),
                        SizedBox(width: 8),
                        Text(
                          'Détail Financier à l\'Entrée (FCFA XAF)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildCostRow('Loyer Mensuel', CurrencyFormatter.formatXAF(item.loyerMensuel)),
                    _buildCostRow(
                      'Avance (${item.avanceMois} mois)',
                      CurrencyFormatter.formatXAF(financial['montantAvance']),
                    ),
                    _buildCostRow(
                      'Caution de Garantie (${item.cautionMois} mois)',
                      CurrencyFormatter.formatXAF(financial['montantCaution']),
                    ),
                    const Divider(height: 20),
                    _buildCostRow(
                      'Total pour Entrer dans les Lieux',
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
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: AppColors.accentGold),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Position exacte masquée (~200m). Le contact direct de l\'agent certifié et l\'itinéraire vous seront remis dès la réservation de visite.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // MoMo visit CTA
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.phone_android),
                label: const Text('Réserver Visite Garantie (2 000 FCFA MoMo)'),
                onPressed: () => _showMoMoModal(context),
              ),
            ),
          ],
        ),
      ),
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

  void _showMoMoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paiement des Frais de Visite (2 000 FCFA)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Remboursement garanti automatique en cas d\'indisponibilité du bien.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Numéro Mobile Money (MTN / Orange)',
                prefixText: '+237 ',
                hintText: '6XXXXXXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demande de paiement MoMo envoyée ! Validez le prompt USSD sur votre téléphone.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: const Text('Valider et Payer via MoMo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
