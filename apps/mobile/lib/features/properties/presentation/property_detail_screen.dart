import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../../core/widgets/photo_gallery_viewer.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final PageController _photoController = PageController();
  int _photoIndex = 0;
  // Révélation locale (à cet écran) des photos malgré le Mode Économie de
  // Données actif — un tap explicite de l'utilisateur outrepasse le masquage
  // automatique, sans changer le réglage global `dataSaverModeProvider`.
  bool _photosReveleesManuellement = false;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

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
    final isDataSaver = ref.watch(dataSaverModeProvider);
    // Cohérent avec le catalogue (property_list_screen.dart / AnnonceCard) :
    // le Mode Économie de Données masque les photos par défaut ici aussi,
    // avec un tap explicite pour les charger malgré tout sur cet écran.
    final afficherPhotos = item.photos.isNotEmpty && (!isDataSaver || _photosReveleesManuellement);

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
            // Banner Photo — galerie défilable, plein écran au tap
            // (masqué par défaut en Mode Économie de Données, cf. `afficherPhotos`)
            if (afficherPhotos)
              _buildPhotoBanner(item.photos)
            else if (item.photos.isNotEmpty)
              _buildPhotoBannerMasque(),
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

            // Contact direct bailleur — WhatsApp + Appel (plus d'agent intermédiaire)
            _buildContactSection(item.bailleurTel, item.bailleurWhatsapp, item.titre),

            const SizedBox(height: 16),
            _buildCandidatureSection(item.id),

            const SizedBox(height: 12),
            _buildVisiteSection(item.id),
          ],
        ),
      ),
    );
  }

  /// Le dossier de candidature se dépose librement (le bailleur peut être
  /// contacté directement en WhatsApp/appel avant d'avoir visité) — c'est
  /// l'acceptation de ce dossier par le bailleur qui, ensuite, débloque le
  /// signal de visite plus bas (`_buildVisiteSection`).
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

  Widget _buildPhotoImage(String url) {
    return url.startsWith('http')
        ? Image.network(url, fit: BoxFit.cover)
        : Image.file(File(url.replaceAll('file://', '')), fit: BoxFit.cover);
  }

  /// Remplace le bandeau photo quand le Mode Économie de Données est actif :
  /// aucune image n'est chargée tant que l'utilisateur n'a pas explicitement
  /// tapé pour les révéler sur cet écran (voir `_photosReveleesManuellement`).
  Widget _buildPhotoBannerMasque() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: InkWell(
          onTap: () => setState(() => _photosReveleesManuellement = true),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.data_saver_off, color: Colors.grey, size: 32),
                const SizedBox(height: 8),
                Text(
                  context.tr('detail_photos_hidden_data_saver'),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('detail_photos_tap_to_load'),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBanner(List<String> photos) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              controller: _photoController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _photoIndex = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PhotoGalleryViewer(photos: photos, initialIndex: i),
                )),
                child: _buildPhotoImage(photos[i]),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    final actif = i == _photoIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: actif ? 9 : 6,
                      height: actif ? 9 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: actif ? Colors.white : Colors.white38,
                      ),
                    );
                  }),
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

  /// 📞 Contact direct bailleur — WhatsApp + Appel, visibles sans étape intermédiaire
  /// (plus d'agent, plus de frais de visite : on connecte locataire et bailleur directement).
  Widget _buildContactSection(String? tel, String? whatsapp, String titreAnnonce) {
    if ((tel == null || tel.isEmpty) && (whatsapp == null || whatsapp.isEmpty)) {
      return const SizedBox();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('detail_contact_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(context.tr('detail_contact_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 14),
            Row(
              children: [
                if (whatsapp != null && whatsapp.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                      label: FittedBox(child: Text(context.tr('detail_contact_whatsapp'), style: const TextStyle(color: Colors.white))),
                      onPressed: () => _lancerWhatsapp(whatsapp, titreAnnonce),
                    ),
                  ),
                if (whatsapp != null && whatsapp.isNotEmpty && tel != null && tel.isNotEmpty) const SizedBox(width: 8),
                if (tel != null && tel.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      icon: const Icon(Icons.call, color: AppColors.primary, size: 18),
                      label: FittedBox(child: Text(context.tr('detail_contact_call'), style: const TextStyle(color: AppColors.primary))),
                      onPressed: () => _lancerAppel(tel),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lancerWhatsapp(String numero, String titreAnnonce) async {
    final numeroNettoye = numero.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent('Bonjour, je suis intéressé(e) par votre annonce "$titreAnnonce" sur LocaDirect.');
    final uri = Uri.parse('https://wa.me/$numeroNettoye?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('detail_contact_error'))));
    }
  }

  Future<void> _lancerAppel(String numero) async {
    final uri = Uri.parse('tel:$numero');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('detail_contact_error'))));
    }
  }

  /// ✅ Déclaration de visite + signal de conformité (remplace l'ancien check-in
  /// agent/paiement : la visite se négocie directement avec le bailleur via
  /// WhatsApp/appel ci-dessus, l'app ne sert plus qu'à recueillir le retour terrain).
  /// Réservé au locataire dont le dossier a été accepté par le bailleur — tant
  /// que ce n'est pas le cas, la section (et son bouton) n'apparaît pas du tout.
  Widget _buildVisiteSection(String annonceId) {
    final candidatures = ref.watch(candidaturesProvider);
    CandidatureModel? candidature;
    try {
      candidature = candidatures.firstWhere((c) => c.annonceId == annonceId);
    } catch (_) {
      candidature = null;
    }
    if (candidature?.statut != CandidatureStatus.acceptee) {
      return const SizedBox.shrink();
    }

    final visites = ref.watch(visitesProvider);
    VisitModel? visite;
    try {
      visite = visites.firstWhere((v) => v.annonceId == annonceId);
    } catch (_) {
      visite = null;
    }

    if (visite == null) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentGold)),
          icon: const Icon(Icons.task_alt, color: AppColors.accentGold),
          label: Text(context.tr('detail_declare_visit'), style: const TextStyle(color: AppColors.accentGold)),
          onPressed: _declarerVisite,
        ),
      );
    }

    if (visite.status.peutEtreClotureeParLocataire) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('detail_visit_declared'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.crimson), padding: const EdgeInsets.symmetric(horizontal: 4)),
                    onPressed: () => _signalerNonConforme(visite!.id),
                    child: FittedBox(child: Text(context.tr('detail_visit_non_conforme'), style: const TextStyle(color: AppColors.crimson, fontSize: 12))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                    onPressed: () => _confirmerConforme(visite!.id),
                    child: FittedBox(child: Text(context.tr('detail_visit_conforme'), style: const TextStyle(fontSize: 12))),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final statutLabel = context.tr(visite.status.labelKey);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('${context.tr('detail_visit_status_prefix')}$statutLabel', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _declarerVisite() async {
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

    final erreur = context.tr('detail_visit_error');
    final result = await ref.read(visitesRepositoryProvider).demanderVisite(widget.propertyId);
    if (!mounted) return;
    if (result['success'] == true) {
      ref.read(visitesProvider.notifier).refresh();
    } else {
      _showResultSnackBar(result['message'] ?? erreur, isError: true);
    }
  }

  Future<void> _confirmerConforme(String visiteId) async {
    final succes = context.tr('detail_visit_confirmed_message');
    final erreur = context.tr('visit_confirm_error');
    final result = await ref.read(visitesRepositoryProvider).confirmerVisite(visiteId);
    if (!mounted) return;
    if (result['success'] == true) {
      ref.read(visitesProvider.notifier).refresh();
      _showResultSnackBar(succes, isError: false);
    } else {
      _showResultSnackBar(result['message'] ?? erreur, isError: true);
    }
  }

  Future<void> _signalerNonConforme(String visiteId) async {
    final motifs = {
      'INDISPONIBLE': context.tr('visit_motif_indisponible'),
      'NON_CONFORME': context.tr('visit_motif_non_conforme'),
      'BAILLEUR_INJOIGNABLE': context.tr('visit_motif_bailleur_injoignable'),
      'PRIX_DIFFERENT': context.tr('visit_motif_prix_different'),
    };
    String? motifChoisi;
    final detailsCtrl = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder est nécessaire ici : sans lui, `onChanged` ne
        // déclenche aucun rebuild et le radio sélectionné ne s'affiche jamais
        // coché (bug remonté : "j'arrive pas" à choisir une raison).
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tr('detail_visit_non_conforme')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...motifs.entries.map((e) => RadioListTile<String>(
                      title: Text(e.value, style: const TextStyle(fontSize: 13)),
                      value: e.key,
                      groupValue: motifChoisi,
                      onChanged: (val) => setDialogState(() => motifChoisi = val),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr('visit_report_details_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
            ElevatedButton(
              onPressed: motifChoisi == null
                  ? null
                  : () => Navigator.pop(ctx, {'motif': motifChoisi!, 'details': detailsCtrl.text.trim()}),
              child: Text(context.tr('visit_report_confirm_button')),
            ),
          ],
        ),
      ),
    );
    detailsCtrl.dispose();
    if (result == null || !mounted) return;

    final succes = context.tr('visit_report_received');
    final erreur = context.tr('visit_report_error');
    final apiResult = await ref.read(visitesRepositoryProvider).contesterVisite(
          visiteId,
          motif: result['motif']!,
          details: (result['details']?.isEmpty ?? true) ? null : result['details'],
        );
    if (!mounted) return;
    if (apiResult['success'] == true) {
      ref.read(visitesProvider.notifier).refresh();
      _showResultSnackBar(succes, isError: false);
    } else {
      _showResultSnackBar(apiResult['message'] ?? erreur, isError: true);
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
