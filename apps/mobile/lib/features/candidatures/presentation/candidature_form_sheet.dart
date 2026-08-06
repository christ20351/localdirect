import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import 'candidatures_provider.dart';

/// Formulaire de dépôt de dossier de candidature (revenu, occupants, garant),
/// affiché en bottom sheet depuis la fiche d'une annonce.
class CandidatureFormSheet extends ConsumerStatefulWidget {
  final String annonceId;

  const CandidatureFormSheet({super.key, required this.annonceId});

  @override
  ConsumerState<CandidatureFormSheet> createState() => _CandidatureFormSheetState();
}

class _CandidatureFormSheetState extends ConsumerState<CandidatureFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _revenuCtrl = TextEditingController();
  final _occupantsCtrl = TextEditingController(text: '1');
  final _messageCtrl = TextEditingController();
  final _garantNomCtrl = TextEditingController();
  final _garantTelCtrl = TextEditingController();
  final _garantProfessionCtrl = TextEditingController();

  String _sourceRevenu = 'SALAIRE';
  String _garantLien = 'PARENT';
  bool _avecGarant = false;
  bool _isSubmitting = false;
  bool _garantPrerempli = false;

  static const _liensGarantConnus = {'PARENT', 'EMPLOYEUR', 'AMI'};

  @override
  void initState() {
    super.initState();
    // Dossier locataire portable (spec §1.4.C) : préremplit le garant avec
    // celui de la dernière candidature soumise par ce locataire (`GET
    // /moi/candidatures`, trié du plus récent au plus ancien côté API),
    // pour éviter de le ressaisir à chaque nouvelle candidature. Reste
    // entièrement modifiable — ce n'est qu'une suggestion de départ.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final candidatures = ref.read(candidaturesProvider);
      final derniereAvecGarant = candidatures
          .where((c) => c.garant != null && c.garant!.nomComplet.isNotEmpty)
          .toList();
      if (derniereAvecGarant.isEmpty) return;
      final garant = derniereAvecGarant.first.garant!;
      setState(() {
        _avecGarant = true;
        _garantPrerempli = true;
        _garantNomCtrl.text = garant.nomComplet;
        _garantTelCtrl.text = garant.telephone;
        _garantProfessionCtrl.text = garant.profession ?? '';
        if (garant.lien != null && _liensGarantConnus.contains(garant.lien)) {
          _garantLien = garant.lien!;
        }
      });
    });
  }

  Map<String, String> _sourcesRevenu(BuildContext context) => {
        'SALAIRE': context.tr('candidature_source_salaire'),
        'COMMERCE': context.tr('candidature_source_commerce'),
        'ARTISANAT': context.tr('candidature_source_artisanat'),
        'ETUDIANT': context.tr('candidature_source_etudiant'),
        'DIASPORA': context.tr('candidature_source_diaspora'),
      };

  Map<String, String> _liensGarant(BuildContext context) => {
        'PARENT': context.tr('candidature_relation_parent'),
        'EMPLOYEUR': context.tr('candidature_relation_employeur'),
        'AMI': context.tr('candidature_relation_ami'),
      };

  @override
  void dispose() {
    _revenuCtrl.dispose();
    _occupantsCtrl.dispose();
    _messageCtrl.dispose();
    _garantNomCtrl.dispose();
    _garantTelCtrl.dispose();
    _garantProfessionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(candidaturesRepositoryProvider);
    final result = await repo.soumettreCandidature(
      widget.annonceId,
      revenuDeclare: int.tryParse(_revenuCtrl.text.trim()),
      sourceRevenu: _sourceRevenu,
      nbOccupants: int.tryParse(_occupantsCtrl.text.trim()),
      message: _messageCtrl.text.trim(),
      garantNomComplet: _avecGarant ? _garantNomCtrl.text.trim() : null,
      garantTelephone: _avecGarant ? _garantTelCtrl.text.trim() : null,
      garantProfession: _avecGarant ? _garantProfessionCtrl.text.trim() : null,
      garantLien: _avecGarant ? _garantLien : null,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ref.read(candidaturesProvider.notifier).refresh();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('candidature_sent')), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? context.tr('candidature_send_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('candidature_form_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                context.tr('candidature_form_subtitle'),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _revenuCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('candidature_income_label')),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('candidature_field_required') : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _sourceRevenu,
                decoration: InputDecoration(labelText: context.tr('candidature_income_source')),
                items: _sourcesRevenu(context).entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _sourceRevenu = v ?? _sourceRevenu),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _occupantsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('candidature_occupants')),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('candidature_field_required') : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _messageCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: context.tr('candidature_message')),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('candidature_add_guarantor')),
                subtitle: _garantPrerempli
                    ? Text(context.tr('candidature_guarantor_prefilled'), style: const TextStyle(color: AppColors.primary, fontSize: 11))
                    : null,
                value: _avecGarant,
                onChanged: (v) => setState(() => _avecGarant = v),
              ),

              if (_avecGarant) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _garantNomCtrl,
                  decoration: InputDecoration(labelText: context.tr('candidature_guarantor_name')),
                  validator: (v) => _avecGarant && (v == null || v.trim().isEmpty) ? context.tr('candidature_field_required') : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _garantTelCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: context.tr('candidature_guarantor_phone'), prefixText: '+237 '),
                  validator: (v) => _avecGarant && (v == null || v.trim().isEmpty) ? context.tr('candidature_field_required') : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _garantProfessionCtrl,
                  decoration: InputDecoration(labelText: context.tr('candidature_guarantor_profession')),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _garantLien,
                  decoration: InputDecoration(labelText: context.tr('candidature_guarantor_relation')),
                  items: _liensGarant(context).entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() => _garantLien = v ?? _garantLien),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('candidature_submit')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
