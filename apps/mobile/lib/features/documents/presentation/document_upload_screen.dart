import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/document_model.dart';
import 'documents_provider.dart';

/// Écran réutilisable de soumission de documents justificatifs — sert à la fois
/// pour la preuve de propriété (devenir Bailleur, seuil sur 4 types) et pour
/// le KYC Agent (CNI recto/verso + Selfie, tous requis).
///
/// Flux : l'utilisateur photographie/choisit chaque document requis, qui reste
/// en local (aperçu "prêt à l'envoi") — rien n'est envoyé au serveur tant qu'il
/// n'a pas explicitement appuyé sur "Envoyer ma demande" en bas de l'écran,
/// une fois tous les documents requis prêts. L'upload est alors réel
/// (multipart) et vraiment revu par le Staff, pas une simulation.
class DocumentUploadScreen extends ConsumerStatefulWidget {
  final List<String> typesRequis;
  final int seuilRequis;
  final String titreKey;
  final String sousTitreKey;

  const DocumentUploadScreen({
    super.key,
    required this.typesRequis,
    required this.seuilRequis,
    required this.titreKey,
    required this.sousTitreKey,
  });

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, XFile> _staged = {};
  bool _envoiEnCours = false;

  bool _estCouvertParServeur(DocumentStatus? statut) => statut == DocumentStatus.valide || statut == DocumentStatus.enAttente;

  Future<void> _choisirPhoto(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.tr('document_source_camera')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.tr('document_source_gallery')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final XFile? fichier = await _picker.pickImage(source: source, imageQuality: 85);
    if (fichier == null || !mounted) return;

    // Aperçu avant validation : l'utilisateur garde ("Valider") ou reprend la photo.
    // Le fichier reste local (staged) — l'envoi réel n'a lieu qu'au clic sur le
    // bouton global "Envoyer ma demande" en bas de l'écran.
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(TypesDocuments.labelKey(type))),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.file(File(fichier.path), height: 220, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('document_retake'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('document_confirm_submit'))),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    setState(() => _staged[type] = fichier);
  }

  Future<void> _envoyerLaDemande() async {
    if (_staged.isEmpty) return;
    setState(() => _envoiEnCours = true);

    final typesEnEchec = <String>[];
    for (final entry in _staged.entries.toList()) {
      final result = await ref.read(documentsRepositoryProvider).soumettre(cheminFichier: entry.value.path, type: entry.key);
      if (result['success'] == true) {
        _staged.remove(entry.key);
      } else {
        typesEnEchec.add(entry.key);
      }
    }

    setState(() => _envoiEnCours = false);
    if (!mounted) return;

    ref.read(mesDocumentsCompteProvider.notifier).refresh();
    final echecs = typesEnEchec.map((t) => context.tr(TypesDocuments.labelKey(t))).toList();

    if (echecs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('document_request_sent')), backgroundColor: AppColors.primary),
      );
      Navigator.of(context).maybePop();
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('document_submit_error')} : ${echecs.join(", ")}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(mesDocumentsCompteProvider);
    final nbPrets = widget.typesRequis.where((t) {
      final statut = _dernierStatutPourType(documents, t);
      return _estCouvertParServeur(statut) || _staged.containsKey(t);
    }).length;
    final seuilAtteint = nbPrets >= widget.seuilRequis;
    final toutDejaEnvoye = seuilAtteint && _staged.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.titreKey))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mesDocumentsCompteProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
          children: [
            Text(context.tr(widget.sousTitreKey), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (nbPrets / widget.seuilRequis).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              '$nbPrets / ${widget.seuilRequis} ${context.tr('document_ready_of')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            ...widget.typesRequis.map((type) => _buildTypeCard(context, type, _dernierStatutPourType(documents, type), documents)),
            if (toutDejaEnvoye) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(context.tr('document_all_already_sent'), style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: toutDejaEnvoye
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (seuilAtteint && !_envoiEnCours) ? _envoyerLaDemande : null,
                    child: _envoiEnCours
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(seuilAtteint
                            ? context.tr('document_send_request')
                            : '${context.tr('document_missing_before_send')} (${widget.seuilRequis - nbPrets})'),
                  ),
                ),
              ),
            ),
    );
  }

  DocumentStatus? _dernierStatutPourType(List<DocumentModel> documents, String type) {
    final correspondants = documents.where((d) => d.type == type && d.bienId == null).toList();
    if (correspondants.isEmpty) return null;
    correspondants.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return correspondants.first.statut;
  }

  Widget _buildTypeCard(BuildContext context, String type, DocumentStatus? statut, List<DocumentModel> documents) {
    final motifRejet = statut == DocumentStatus.rejete
        ? documents.firstWhere((d) => d.type == type && d.bienId == null, orElse: () => documents.first).motifRejet
        : null;

    final estStaged = _staged.containsKey(type);
    final bloqueParServeur = _estCouvertParServeur(statut);

    final (icon, color, statutLabel) = estStaged
        ? (Icons.check_circle_outline, AppColors.primary, context.tr('document_statut_pret'))
        : switch (statut) {
            DocumentStatus.valide => (Icons.check_circle, Colors.green, context.tr(DocumentStatus.valide.labelKey)),
            DocumentStatus.enAttente => (Icons.hourglass_top, AppColors.accentGold, context.tr(DocumentStatus.enAttente.labelKey)),
            DocumentStatus.rejete => (Icons.cancel, AppColors.crimson, context.tr(DocumentStatus.rejete.labelKey)),
            _ => (Icons.upload_file_outlined, Colors.grey, context.tr(DocumentStatus.nonSoumis.labelKey)),
          };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: estStaged
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.file(File(_staged[type]!.path), width: 44, height: 44, fit: BoxFit.cover),
              )
            : Icon(icon, color: color),
        title: Text(context.tr(TypesDocuments.labelKey(type))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statutLabel, style: TextStyle(color: color, fontSize: 12)),
            if (motifRejet != null && motifRejet.isNotEmpty)
              Text(motifRejet, style: const TextStyle(color: AppColors.crimson, fontSize: 11)),
          ],
        ),
        trailing: bloqueParServeur
            ? null
            : IconButton(
                tooltip: context.tr(estStaged ? 'document_retake' : (statut == DocumentStatus.rejete ? 'document_resubmit' : 'document_take_photo')),
                icon: Icon(estStaged ? Icons.refresh : Icons.camera_alt_outlined, color: AppColors.primary),
                onPressed: () => _choisirPhoto(type),
              ),
      ),
    );
  }
}
