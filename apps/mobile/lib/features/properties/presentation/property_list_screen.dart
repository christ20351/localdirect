import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'property_provider.dart';
import '../models/property_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/annonce_card.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../visits/presentation/visites_provider.dart';
import '../../visits/models/visit_model.dart';
import '../../alertes/presentation/alertes_provider.dart';

class PropertyListScreen extends ConsumerStatefulWidget {
  const PropertyListScreen({super.key});

  @override
  ConsumerState<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends ConsumerState<PropertyListScreen> {
  int _currentTabIndex = 0;
  String _selectedFilter = 'TOUS';

  /// Recharge le catalogue depuis l'API en combinant ville + type + filtres étendus.
  void _applyFilters(VilleOption? ville) {
    ref.read(propertiesProvider.notifier).refresh(
          villeSlug: ville?.slug,
          type: _selectedFilter == 'TOUS' ? null : _selectedFilter,
          filtres: ref.read(searchFiltersProvider),
        );
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final isDataSaver = ref.watch(dataSaverModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home_work_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('LocaDirect CM'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Économie de Data 3G
          if (isDataSaver)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: AppColors.accentGold.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.accentGold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('explore_data_saver_banner'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGold),
                  ),
                ],
              ),
            ),

          // Contenu principal selon l'onglet actif
          Expanded(
            child: _currentTabIndex == 3
                ? _buildProfileTab(context)
                : _currentTabIndex == 1
                    ? _buildVisitsTab(context)
                    : _currentTabIndex == 2
                        ? _buildFavoritesTab(context, ref, properties)
                        : _buildLocataireExplorerView(context, properties, isDataSaver),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.explore), label: context.tr('nav_explore')),
          NavigationDestination(icon: const Icon(Icons.confirmation_number), label: context.tr('nav_visits')),
          NavigationDestination(icon: const Icon(Icons.favorite), label: context.tr('nav_favorites')),
          NavigationDestination(icon: const Icon(Icons.person), label: context.tr('nav_profile')),
        ],
      ),
    );
  }

  // =========================================================
  // 1. ONGLET EXPLORER (Locataire)
  // =========================================================
  Widget _buildLocataireExplorerView(BuildContext context, List<PropertyModel> properties, bool isDataSaver) {
    final filtered = _selectedFilter == 'TOUS'
        ? properties
        : properties.where((p) => p.typeBien == _selectedFilter).toList();

    final filtresActifs = ref.watch(searchFiltersProvider);
    final selectedVille = ref.watch(selectedVilleProvider);
    final villesAsync = ref.watch(villesListProvider);

    return Column(
      children: [
        // Barre de localisation ("Recherche à Douala ▾")
        InkWell(
          onTap: () => _showVilleSheet(context, villesAsync.asData?.value ?? const []),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  selectedVille?.nom ?? context.tr('common_all_cities'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),

        // Barres de filtres rapide
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['TOUS', 'STUDIO', 'APPARTEMENT', 'CHAMBRE_MODERNE'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          onSelected: (_) {
                            setState(() => _selectedFilter = filter);
                            _applyFilters(ref.read(selectedVilleProvider));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: filtresActifs.nbActifs > 0,
                label: Text('${filtresActifs.nbActifs}'),
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.tune),
                  tooltip: context.tr('explore_filters_advanced'),
                  onPressed: () => _showFiltresSheet(context),
                ),
              ),
            ],
          ),
        ),

        // Liste des biens
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applyFilters(ref.read(selectedVilleProvider)),
            child: filtered.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('explore_empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final favoris = ref.watch(favoritesProvider);
                      return AnnonceCard(
                        item: item,
                        isDataSaver: isDataSaver,
                        isFavori: favoris.contains(item.id),
                        onTap: () => context.push('/property/${item.id}'),
                        onFavoriToggle: () => ref.read(favoritesProvider.notifier).toggle(item.id),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // 2. ONGLET MES VISITES
  // =========================================================
  Widget _buildVisitsTab(BuildContext context) {
    final visites = ref.watch(visitesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(visitesProvider.notifier).refresh(),
      child: visites.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              children: [
                Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(
                  context.tr('visits_empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visites.length,
              itemBuilder: (context, index) => _buildVisitCard(visites[index]),
            ),
    );
  }

  Widget _buildVisitCard(VisitModel visite) {
    final statutColor = switch (visite.status) {
      VisitStatus.confirmee => Colors.green,
      VisitStatus.remboursee || VisitStatus.contestee || VisitStatus.annulee || VisitStatus.noShow => AppColors.crimson,
      VisitStatus.demandee => Colors.grey,
      _ => AppColors.accentGold,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(context.tr(visite.status.labelKey), style: const TextStyle(fontSize: 11)),
                  backgroundColor: statutColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statutColor, fontWeight: FontWeight.bold),
                  side: BorderSide.none,
                ),
                Text(
                  '${CurrencyFormatter.formatXAF(visite.feeAmountXAF)} ${visite.status == VisitStatus.demandee ? context.tr('visit_fee_to_pay') : context.tr('visit_fee_paid')}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              visite.annonce?.titre ?? context.tr('visit_default_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (visite.annonce?.quartier != null) ...[
              const SizedBox(height: 4),
              Text('${visite.annonce?.ville ?? ""} — ${visite.annonce?.quartier}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
            if (visite.motifContestation != null) ...[
              const SizedBox(height: 8),
              Text('${context.tr('visit_reported_motif')}${visite.motifContestation}', style: const TextStyle(color: AppColors.crimson, fontSize: 12)),
            ],
            if (visite.confirmationCode != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('visit_give_code'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      visite.confirmationCode!.split('').join(' '),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.accentGold),
                    ),
                  ],
                ),
              ),
            ],
            if (visite.status.peutEtreClotureeParLocataire) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.crimson)),
                      onPressed: () => _signalerProbleme(visite),
                      child: Text(context.tr('visit_report_problem'), style: const TextStyle(color: AppColors.crimson, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmerVisite(visite),
                      child: Text(context.tr('visit_confirm_ok'), style: const TextStyle(fontSize: 12)),
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

  Future<void> _confirmerVisite(VisitModel visite) async {
    final result = await ref.read(visitesRepositoryProvider).confirmerVisite(visite.id);
    if (!mounted) return;
    if (result['success'] == true) {
      ref.read(visitesProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('visit_confirmed_message')), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? context.tr('visit_confirm_error'))),
      );
    }
  }

  Future<void> _signalerProbleme(VisitModel visite) async {
    final motifs = {
      'INDISPONIBLE': context.tr('visit_motif_indisponible'),
      'NON_CONFORME': context.tr('visit_motif_non_conforme'),
      'AGENT_ABSENT': context.tr('visit_motif_agent_absent'),
      'PRIX_DIFFERENT': context.tr('visit_motif_prix_different'),
    };
    String? motifChoisi;

    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('visit_report_problem')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: motifs.entries
              .map((e) => RadioListTile<String>(
                    title: Text(e.value, style: const TextStyle(fontSize: 13)),
                    value: e.key,
                    groupValue: motifChoisi,
                    onChanged: (val) => motifChoisi = val,
                  ))
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, motifChoisi),
            child: Text(context.tr('visit_report_confirm_button')),
          ),
        ],
      ),
    );

    if (motif == null) return;

    final result = await ref.read(visitesRepositoryProvider).contesterVisite(visite.id, motif: motif);
    if (!mounted) return;
    if (result['success'] == true) {
      ref.read(visitesProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('visit_report_received')), backgroundColor: AppColors.accentGold),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? context.tr('visit_report_error'))),
      );
    }
  }

  // =========================================================
  // 3. ONGLET FAVORIS
  // =========================================================
  Widget _buildFavoritesTab(BuildContext context, WidgetRef ref, List<PropertyModel> properties) {
    final favoris = ref.watch(favoritesProvider);
    final favProperties = properties.where((p) => favoris.contains(p.id)).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('favorites_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (favProperties.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('favorites_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: favProperties.length,
              itemBuilder: (context, index) {
                final p = favProperties[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.redAccent),
                    title: Text(p.titre),
                    subtitle: Text('${p.quartier} — ${CurrencyFormatter.formatXAF(p.loyerMensuel)}${context.tr('favorites_per_month')}'),
                    trailing: ElevatedButton(
                      onPressed: () => context.push('/property/${p.id}'),
                      child: Text(context.tr('common_see')),
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

  // =========================================================
  // 4. ONGLET MON PROFIL
  // =========================================================
  Widget _buildProfileTab(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(currentUserProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => user == null
                  ? _buildGuestCard(context)
                  : _buildUserCard(user),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => _buildGuestCard(context),
            ),

            const SizedBox(height: 24),

            userAsync.maybeWhen(
              data: (user) => user != null
                  ? Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.other_houses_outlined, color: AppColors.accentGold),
                            title: const Text('Espace Bailleur — Patrimoine & Baux'),
                            subtitle: const Text('Examen des candidatures et suivi fiscal (10%)'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/bailleur'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.folder_shared_outlined, color: AppColors.primary),
                            title: Text(context.tr('profile_candidatures_link')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/candidatures'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                            title: Text(context.tr('profile_alertes_link')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/alertes'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(context.tr('settings_title')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
              orElse: () => const SizedBox(),
            ),

            const SizedBox(height: 24),

            userAsync.maybeWhen(
              data: (user) => user != null
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: Text(context.tr('profile_logout'), style: const TextStyle(color: Colors.redAccent)),
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).deconnexion();
                          ref.invalidate(currentUserProvider);
                          if (!context.mounted) return;
                          context.go('/auth/login');
                        },
                      ),
                    )
                  : const SizedBox(),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_circle_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(context.tr('profile_guest_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              context.tr('profile_guest_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/auth/login'),
                child: Text(context.tr('detail_login_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final nomComplet = (user['nomComplet'] as String?)?.trim();
    final telephone = user['telephone'] as String?;
    final statutKyc = user['statutKyc'] as String? ?? 'NON_SOUMIS';
    final kycLabel = switch (statutKyc) {
      'VALIDE' => context.tr('kyc_verified'),
      'EN_ATTENTE' => context.tr('kyc_pending'),
      'REJETE' => context.tr('kyc_rejected'),
      _ => context.tr('kyc_not_submitted'),
    };
    final kycColor = switch (statutKyc) {
      'VALIDE' => Colors.green,
      'EN_ATTENTE' => AppColors.accentGold,
      'REJETE' => AppColors.crimson,
      _ => Colors.grey,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (nomComplet == null || nomComplet.isEmpty) ? context.tr('profile_incomplete') : nomComplet,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(telephone ?? '—', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kycColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(kycLabel, style: TextStyle(color: kycColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVilleSheet(BuildContext context, List<VilleOption> villes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(context.tr('ville_sheet_title'), style: AppTextStyles.title),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(context.tr('common_all_cities')),
              trailing: ref.read(selectedVilleProvider) == null ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                ref.read(selectedVilleProvider.notifier).state = null;
                Navigator.pop(ctx);
                _applyFilters(null);
              },
            ),
            ...villes.map((v) => ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(v.nom),
                  trailing: ref.read(selectedVilleProvider)?.id == v.id ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    ref.read(selectedVilleProvider.notifier).state = v;
                    Navigator.pop(ctx);
                    _applyFilters(v);
                  },
                )),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showFiltresSheet(BuildContext context) {
    final courants = ref.read(searchFiltersProvider);
    final loyerMinCtrl = TextEditingController(text: courants.loyerMin?.toString() ?? '');
    final loyerMaxCtrl = TextEditingController(text: courants.loyerMax?.toString() ?? '');
    int? avanceMax = courants.avanceMax;
    bool? meuble = courants.meuble;
    int? nbPieces = courants.nbPieces;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('explore_filters_advanced'), style: AppTextStyles.title),
                    TextButton(
                      onPressed: () => setModalState(() {
                        loyerMinCtrl.clear();
                        loyerMaxCtrl.clear();
                        avanceMax = null;
                        meuble = null;
                        nbPieces = null;
                      }),
                      child: Text(context.tr('filters_reset')),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Text(context.tr('filters_budget'), style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: loyerMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.tr('filters_min')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: loyerMaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.tr('filters_max')),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),
                Text(context.tr('filters_advance_max'), style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 4, 5, 6].map((mois) {
                    return ChoiceChip(
                      label: Text('$mois ${context.tr('filters_month_unit')}'),
                      selected: avanceMax == mois,
                      onSelected: (_) => setModalState(() => avanceMax = avanceMax == mois ? null : mois),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),
                Text(context.tr('filters_furnished'), style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<bool?>(
                  segments: [
                    ButtonSegment(value: null, label: Text(context.tr('filters_indifferent'))),
                    ButtonSegment(value: true, label: Text(context.tr('filters_furnished_yes'))),
                    ButtonSegment(value: false, label: Text(context.tr('filters_furnished_no'))),
                  ],
                  selected: {meuble},
                  onSelectionChanged: (val) => setModalState(() => meuble = val.first),
                ),

                const SizedBox(height: AppSpacing.lg),
                Text(context.tr('filters_min_rooms'), style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 4].map((n) {
                    return ChoiceChip(
                      label: Text('$n+'),
                      selected: nbPieces == n,
                      onSelected: (_) => setModalState(() => nbPieces = nbPieces == n ? null : n),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final nouveaux = RechercheFiltres(
                        loyerMin: int.tryParse(loyerMinCtrl.text.trim()),
                        loyerMax: int.tryParse(loyerMaxCtrl.text.trim()),
                        avanceMax: avanceMax,
                        meuble: meuble,
                        nbPieces: nbPieces,
                      );
                      ref.read(searchFiltersProvider.notifier).state = nouveaux;
                      Navigator.pop(ctx);
                      _applyFilters(ref.read(selectedVilleProvider));
                    },
                    child: Text(context.tr('filters_apply')),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: Text(context.tr('filters_create_alert')),
                    onPressed: () async {
                      final ville = ref.read(selectedVilleProvider);
                      final success = await ref.read(alertesRepositoryProvider).creerAlerte(
                            villeSlug: ville?.slug,
                            type: _selectedFilter == 'TOUS' ? null : _selectedFilter,
                            loyerMax: int.tryParse(loyerMaxCtrl.text.trim()),
                          );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ref.read(alertesProvider.notifier).refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? context.tr('filters_alert_created') : context.tr('filters_alert_error')),
                          backgroundColor: success ? AppColors.primary : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
