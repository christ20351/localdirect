import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'property_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';

class PropertyListScreen extends ConsumerWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final isDataSaver = ref.watch(dataSaverModeProvider);
    final currentRole = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home_work_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('LocaDirect CM'),
          ],
        ),
        actions: [
          // City selector
          DropdownButton<String>(
            value: selectedCity,
            dropdownColor: Theme.of(context).cardColor,
            underline: const SizedBox(),
            icon: const Icon(Icons.location_city, color: AppColors.primary),
            items: const [
              DropdownMenuItem(value: 'Douala', child: Text('Douala')),
              DropdownMenuItem(value: 'Yaoundé', child: Text('Yaoundé')),
            ],
            onChanged: (val) {
              if (val != null) ref.read(selectedCityProvider.notifier).state = val;
            },
          ),
          const SizedBox(width: 8),
          // Data saver mode toggle
          IconButton(
            tooltip: 'Mode Économie de Data (3G)',
            icon: Icon(
              isDataSaver ? Icons.data_saver_on : Icons.data_saver_off,
              color: isDataSaver ? AppColors.accentGold : Colors.grey,
            ),
            onPressed: () {
              ref.read(dataSaverModeProvider.notifier).state = !isDataSaver;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Role switch banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mode: $currentRole',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'LOCATAIRE', label: Text('Locataire')),
                    ButtonSegment(value: 'AGENT', label: Text('Agent')),
                    ButtonSegment(value: 'BAILLEUR', label: Text('Bailleur')),
                  ],
                  selected: {currentRole},
                  onSelectionChanged: (set) {
                    ref.read(userRoleProvider.notifier).state = set.first;
                  },
                ),
              ],
            ),
          ),

          // Data saver warning banner
          if (isDataSaver)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: AppColors.accentGold.withOpacity(0.2),
              child: const Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.accentGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mode Économie de Data Actif (< 100 Ko par session)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGold),
                  ),
                ],
              ),
            ),

          // Property list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final item = properties[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go('/property/${item.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image banner or placeholder in data saver
                        if (!isDataSaver && item.photos.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              item.photos.first,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 80,
                            color: Theme.of(context).colorScheme.surface,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_aspect_ratio, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Photos désactivées (Économie Data)', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(item.typeBien),
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    side: BorderSide.none,
                                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Visite Garantie',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.titre,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: AppColors.accentGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.quartier} (${item.pointRepere})',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatXAF(item.loyerMensuel),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Avance: ${item.avanceMois} m. | Caution: ${item.cautionMois} m.',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => context.go('/property/${item.id}'),
                                    child: const Text('Voir le bien'),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
