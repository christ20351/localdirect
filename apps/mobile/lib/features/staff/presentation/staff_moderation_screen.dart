import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../documents/models/document_model.dart';
import '../models/staff_models.dart';
import 'staff_provider.dart';

/// Espace de modération minimal pour les comptes Staff/Admin : file des
/// documents (KYC/preuve de propriété) et des biens en attente de vérification.
/// Sans cet écran, personne ne peut jamais faire progresser un dossier soumis
/// depuis le mobile — c'est le chaînon qui manquait pour que la vérification
/// Bailleur/Agent soit utilisable de bout en bout, pas seulement côté API.
class StaffModerationScreen extends ConsumerStatefulWidget {
  const StaffModerationScreen({super.key});

  @override
  ConsumerState<StaffModerationScreen> createState() => _StaffModerationScreenState();
}

class _StaffModerationScreenState extends ConsumerState<StaffModerationScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, Future<Uint8List?>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<Uint8List?> _imageDuDocument(String documentId) {
    return _imageCache.putIfAbsent(documentId, () => ref.read(staffRepositoryProvider).fetchDocumentImage(documentId));
  }

  void _voirEnGrand(Uint8List bytes) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(child: InteractiveViewer(minScale: 1, maxScale: 4, child: Image.memory(bytes, fit: BoxFit.contain))),
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(documentsEnAttenteProvider.notifier).refresh(),
      ref.read(biensEnAttenteProvider.notifier).refresh(),
    ]);
  }

  Future<String?> _demanderMotif(String titre) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: TextField(controller: ctrl, maxLines: 2, decoration: InputDecoration(hintText: context.tr('staff_reject_reason_hint'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(context.tr('staff_reject_confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _validerDocument(StaffDocumentModel d) async {
    final success = await ref.read(staffRepositoryProvider).validerDocument(d.document.id);
    if (!mounted) return;
    if (success) ref.read(documentsEnAttenteProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? context.tr('staff_action_success') : context.tr('staff_action_error'))));
  }

  Future<void> _rejeterDocument(StaffDocumentModel d) async {
    final motif = await _demanderMotif(context.tr('staff_reject_document_title'));
    if (motif == null || !mounted) return;
    final success = await ref.read(staffRepositoryProvider).rejeterDocument(d.document.id, motif);
    if (!mounted) return;
    if (success) ref.read(documentsEnAttenteProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? context.tr('staff_action_success') : context.tr('staff_action_error'))));
  }

  Future<void> _validerBien(StaffBienModel b) async {
    final success = await ref.read(staffRepositoryProvider).validerBien(b.id);
    if (!mounted) return;
    if (success) ref.read(biensEnAttenteProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? context.tr('staff_action_success') : context.tr('staff_action_error'))));
  }

  Future<void> _rejeterBien(StaffBienModel b) async {
    final motif = await _demanderMotif(context.tr('staff_reject_bien_title'));
    if (motif == null || !mounted) return;
    final success = await ref.read(staffRepositoryProvider).rejeterBien(b.id, motif);
    if (!mounted) return;
    if (success) ref.read(biensEnAttenteProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? context.tr('staff_action_success') : context.tr('staff_action_error'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('staff_moderation_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('staff_tab_documents')),
            Tab(text: context.tr('staff_tab_biens')),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildDocumentsTab(context), _buildBiensTab(context)]),
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    final documents = ref.watch(documentsEnAttenteProvider);
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: documents.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              children: [
                Icon(Icons.task_alt, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(context.tr('staff_documents_empty'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final d = documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: _imageDuDocument(d.document.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                            }
                            final bytes = snapshot.data;
                            if (bytes == null) {
                              return SizedBox(
                                height: 80,
                                child: Center(child: Text(context.tr('staff_image_unavailable'), style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                              );
                            }
                            return GestureDetector(
                              onTap: () => _voirEnGrand(bytes),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Image.memory(bytes, height: 160, width: double.infinity, fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(context.tr(TypesDocuments.labelKey(d.document.type)), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${d.utilisateurNom ?? "—"} · ${d.utilisateurTelephone ?? ""}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        if (d.bienReference != null) Text('${context.tr('staff_related_bien')}${d.bienReference}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.crimson, side: const BorderSide(color: AppColors.crimson)),
                                onPressed: () => _rejeterDocument(d),
                                child: Text(context.tr('staff_reject')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(onPressed: () => _validerDocument(d), child: Text(context.tr('staff_approve'))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBiensTab(BuildContext context) {
    final biens = ref.watch(biensEnAttenteProvider);
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: biens.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              children: [
                Icon(Icons.task_alt, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(context.tr('staff_biens_empty'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: biens.length,
              itemBuilder: (context, index) {
                final b = biens[index];
                final creePar = (b.creeParNom != null) ? '${b.creeParNom} (${b.creeParRoles.join(", ")})' : '—';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (b.photos.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(b.photos.first, height: 140, width: double.infinity, fit: BoxFit.cover),
                          ),
                        const SizedBox(height: 8),
                        Text(b.titre ?? b.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${b.ville ?? ""} — ${b.quartier ?? ""}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        if (b.loyerMensuelXAF != null)
                          Text(CurrencyFormatter.formatXAF(b.loyerMensuelXAF!), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${context.tr('staff_created_by')}$creePar', style: const TextStyle(fontSize: 11)),
                        if (b.bailleurNom != null) Text('${context.tr('staff_landlord')}${b.bailleurNom} · ${b.bailleurTelephone ?? ""}', style: const TextStyle(fontSize: 11)),
                        if (b.bailleurNom == null && b.bailleurTelBrut != null) Text('${context.tr('staff_landlord_phone_only')}${b.bailleurTelBrut}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.crimson, side: const BorderSide(color: AppColors.crimson)),
                                onPressed: () => _rejeterBien(b),
                                child: Text(context.tr('staff_reject')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(onPressed: () => _validerBien(b), child: Text(context.tr('staff_approve'))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
