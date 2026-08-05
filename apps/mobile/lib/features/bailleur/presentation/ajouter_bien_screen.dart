import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../properties/presentation/property_provider.dart';
import '../models/bien_model.dart';
import 'bailleur_provider.dart';

class AjouterBienScreen extends ConsumerStatefulWidget {
  final BienModel? bienToEdit;

  const AjouterBienScreen({super.key, this.bienToEdit});

  @override
  ConsumerState<AjouterBienScreen> createState() => _AjouterBienScreenState();
}

class _AjouterBienScreenState extends ConsumerState<AjouterBienScreen> {
  int _currentStep = 0;

  // Contrôleurs de saisie
  final _titreCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _loyerCtrl = TextEditingController();
  final _chargesCtrl = TextEditingController(text: '0');
  final _quartierCustomCtrl = TextEditingController();
  final _repereCtrl = TextEditingController();
  final _accesCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _memeNumeroWhatsapp = true;

  // Valeurs par défaut
  String _typeBien = 'STUDIO';

  // Géographie
  VilleOption? _selectedVille;
  QuartierOption? _selectedQuartier;
  List<VilleOption> _villesDisponibles = [];
  List<QuartierOption> _quartiersDisponibles = [];
  bool _isLoadingGeo = false;
  bool _useCustomQuartier = false;

  int _avanceMois = 3;
  int _cautionMois = 1;
  bool _chargesIncluses = false;
  bool _meuble = false;

  String _compteurEneo = 'INDIVIDUEL';
  String _compteurEau = 'CAMWATER';

  // Gestion des photos depuis la galerie (Max 4)
  final ImagePicker _picker = ImagePicker();
  final List<String> _photosPaths = [];

  final List<String> _equipementsSelectionnes = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initialiserChampsSiEdition();
    _chargerVillesEtQuartiers();
  }

  void _initialiserChampsSiEdition() {
    final b = widget.bienToEdit;
    if (b == null) return;

    _titreCtrl.text = b.titre ?? '';
    _loyerCtrl.text = (b.loyerMensuelXAF ?? 0).toString();
    _quartierCustomCtrl.text = b.quartier ?? '';
    _telephoneCtrl.text = b.bailleurTel ?? '';
    _whatsappCtrl.text = b.bailleurWhatsapp ?? '';
    _memeNumeroWhatsapp = _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _telephoneCtrl.text;
    if (b.type.isNotEmpty) _typeBien = b.type;
    _meuble = b.meuble;
    _useCustomQuartier = (b.quartier != null && b.quartier!.isNotEmpty);
    if (b.photos.isNotEmpty) _photosPaths.addAll(b.photos);
    if (b.equipements.isNotEmpty) _equipementsSelectionnes.addAll(b.equipements);
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    _loyerCtrl.dispose();
    _chargesCtrl.dispose();
    _quartierCustomCtrl.dispose();
    _repereCtrl.dispose();
    _accesCtrl.dispose();
    _telephoneCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  /// 🏙️ Chargement initial des villes et quartiers depuis le repo
  Future<void> _chargerVillesEtQuartiers() async {
    setState(() => _isLoadingGeo = true);
    final repo = PropertiesRepository();
    final villes = await repo.fetchVilles();
    setState(() {
      _villesDisponibles = villes;
      if (villes.isNotEmpty) {
        _selectedVille = villes.firstWhere(
          (v) => widget.bienToEdit?.ville?.toLowerCase() == v.slug,
          orElse: () => villes.first,
        );
      }
    });

    if (_selectedVille != null) {
      await _chargerQuartiersPourVille(_selectedVille!.slug);
    }
    setState(() => _isLoadingGeo = false);
  }

  Future<void> _chargerQuartiersPourVille(String villeSlug) async {
    final repo = PropertiesRepository();
    final quartiers = await repo.fetchQuartiers(villeSlug);
    setState(() {
      _quartiersDisponibles = quartiers;
      if (quartiers.isNotEmpty) {
        _selectedQuartier = quartiers.first;
      } else {
        _selectedQuartier = null;
      }
    });
  }

  /// 📸 Sélection d'images depuis la galerie photo du téléphone
  Future<void> _pickImageFromGallery() async {
    if (_photosPaths.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('bailleur_add_bien_photo_limit'))),
      );
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _photosPaths.add(picked.path);
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('bailleur_add_bien_photo_error'))),
      );
    }
  }

  void _retirerPhoto(int index) {
    setState(() {
      _photosPaths.removeAt(index);
    });
  }

  void _toggleEquipement(String item) {
    setState(() {
      if (_equipementsSelectionnes.contains(item)) {
        _equipementsSelectionnes.remove(item);
      } else {
        _equipementsSelectionnes.add(item);
      }
    });
  }

  /// 🚀 Soumission (Création OU Édition complète du bien)
  Future<void> _soumettreFormulaire() async {
    if (_telephoneCtrl.text.trim().isEmpty || (!_memeNumeroWhatsapp && _whatsappCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('bailleur_add_bien_contact_required'))),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final loyerXAF = int.tryParse(_loyerCtrl.text.trim()) ?? 0;
    final chargesXAF = int.tryParse(_chargesCtrl.text.trim()) ?? 0;

    final customQuartier = _quartierCustomCtrl.text.trim();
    final quartierFinal = customQuartier.isNotEmpty
        ? customQuartier
        : (_selectedQuartier?.nom ?? '');

    // Seules les URL déjà distantes (photos existantes en édition) partent dans le JSON.
    // Les fichiers locaux nouvellement choisis sont uploadés séparément en multipart
    // une fois le bien créé/modifié — un chemin de fichier local n'a aucun sens comme
    // "URL de photo" pour qui que ce soit d'autre que cet appareil.
    final photosDistantes = _photosPaths.where((p) => p.startsWith('http')).toList();
    final photosLocales = _photosPaths.where((p) => !p.startsWith('http')).toList();

    final payload = {
      'titre': _titreCtrl.text.trim().isEmpty ? '${context.tr('bailleur_add_bien_titre_fallback_prefix')} $_typeBien' : _titreCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'type': _typeBien,
      'villeId': _selectedVille?.id ?? 'douala',
      'villeSlug': _selectedVille?.slug ?? 'douala',
      'quartierId': _selectedQuartier?.id,
      'quartierNom': quartierFinal,
      'pointRepereNom': _repereCtrl.text.trim(),
      'indicationAcces': _accesCtrl.text.trim(),
      'loyerMensuel': loyerXAF > 0 ? loyerXAF : 50000,
      'chargesMensuelles': chargesXAF,
      'chargesIncluses': _chargesIncluses,
      'avanceMois': _avanceMois,
      'cautionMois': _cautionMois,
      'meuble': _meuble,
      'equipements': _equipementsSelectionnes,
      'compteurElectricite': _compteurEneo,
      'compteurEau': _compteurEau,
      'photos': photosDistantes,
      'bailleurTel': _telephoneCtrl.text.trim(),
      'whatsapp': _memeNumeroWhatsapp ? _telephoneCtrl.text.trim() : _whatsappCtrl.text.trim(),
    };

    final texteEditSucces = context.tr('bailleur_add_bien_edit_success');
    final texteEditErreur = context.tr('bailleur_add_bien_edit_error');
    final texteCreationSucces = context.tr('bailleur_add_bien_success');

    setState(() => _isSubmitting = true);

    bool isSuccess = false;
    String message = '';
    String? bienId = widget.bienToEdit?.id;

    if (widget.bienToEdit != null) {
      isSuccess = await ref.read(bailleurRepositoryProvider).modifierBien(widget.bienToEdit!.id, payload);
      message = isSuccess ? texteEditSucces : texteEditErreur;
    } else {
      final res = await ref.read(bailleurRepositoryProvider).creerBien(payload);
      isSuccess = (res['success'] == true);
      message = res['message'] ?? texteCreationSucces;
      if (isSuccess) bienId = (res['data'] as Map<String, dynamic>?)?['bienId'] as String?;
    }

    if (isSuccess && bienId != null && photosLocales.isNotEmpty) {
      await ref.read(bailleurRepositoryProvider).ajouterMedias(bienId, photosLocales);
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ref.read(mesBiensProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bienToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? context.tr('bailleur_add_bien_title_edit') : context.tr('bailleur_add_bien_title')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de progression par étapes (Stepper Header Réactif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.tr('bailleur_add_bien_step_label')} ${_currentStep + 1} ${context.tr('bailleur_add_bien_step_of_total')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                      Text(
                        _currentStep == 0
                            ? context.tr('bailleur_add_bien_step1_short')
                            : _currentStep == 1
                                ? context.tr('bailleur_add_bien_step2_short')
                                : _currentStep == 2
                                    ? context.tr('bailleur_add_bien_step3_short')
                                    : context.tr('bailleur_add_bien_step4_short'),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 4,
                      minHeight: 6,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Formulaire dynamique selon l'étape courante
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Barre d'actions (Suivant / Précédent / Publier)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: Text(context.tr('common_previous')),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_currentStep < 3) {
                                setState(() => _currentStep++);
                              } else {
                                _soumettreFormulaire();
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(_currentStep < 3
                              ? '${context.tr('common_next')} ➔'
                              : (isEdit ? context.tr('bailleur_add_bien_save_all') : context.tr('bailleur_add_bien_publish'))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // VUES DES ÉTAPES DU STEPPER
  // =========================================================

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1General();
      case 1:
        return _buildStep2Localisation();
      case 2:
        return _buildStep3Photos();
      case 3:
        return _buildStep4PrixEtValidation();
      default:
        return const SizedBox();
    }
  }

  /// 📍 Étape 1 : Type & Description
  Widget _buildStep1General() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('bailleur_add_bien_step1_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(context.tr('bailleur_add_bien_step1_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 13)),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _typeBien,
          decoration: InputDecoration(labelText: context.tr('bailleur_add_bien_type_label'), prefixIcon: const Icon(Icons.home_work)),
          items: [
            DropdownMenuItem(value: 'STUDIO', child: Text(context.tr('type_bien_studio'))),
            DropdownMenuItem(value: 'APPARTEMENT', child: Text(context.tr('type_bien_appartement'))),
            DropdownMenuItem(value: 'CHAMBRE_MODERNE', child: Text(context.tr('type_bien_chambre_moderne'))),
            DropdownMenuItem(value: 'CHAMBRE_SIMPLE', child: Text(context.tr('type_bien_chambre_simple'))),
            DropdownMenuItem(value: 'DUPLEX', child: Text(context.tr('type_bien_duplex'))),
            DropdownMenuItem(value: 'MAISON', child: Text(context.tr('type_bien_maison'))),
            DropdownMenuItem(value: 'BOUTIQUE', child: Text(context.tr('type_bien_boutique'))),
          ],
          onChanged: (val) => setState(() => _typeBien = val ?? 'STUDIO'),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _titreCtrl,
          decoration: InputDecoration(
            labelText: context.tr('bailleur_add_bien_titre_label'),
            hintText: context.tr('bailleur_add_bien_titre_hint'),
            prefixIcon: const Icon(Icons.title),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: context.tr('bailleur_add_bien_description_label'),
            hintText: context.tr('bailleur_add_bien_description_hint'),
            prefixIcon: const Icon(Icons.notes),
          ),
        ),

        const SizedBox(height: 24),
        Text(context.tr('bailleur_add_bien_contact_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(context.tr('bailleur_add_bien_contact_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 12),

        TextFormField(
          controller: _telephoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.tr('bailleur_add_bien_phone_label'),
            prefixText: '+237 ',
            prefixIcon: const Icon(Icons.call_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 12),

        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _memeNumeroWhatsapp,
          title: Text(context.tr('bailleur_add_bien_same_whatsapp'), style: const TextStyle(fontSize: 13)),
          onChanged: (v) => setState(() => _memeNumeroWhatsapp = v ?? true),
        ),

        if (!_memeNumeroWhatsapp) ...[
          const SizedBox(height: 4),
          TextFormField(
            controller: _whatsappCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: context.tr('bailleur_add_bien_whatsapp_label'),
              prefixText: '+237 ',
              prefixIcon: const Icon(Icons.chat_outlined),
            ),
          ),
        ],
      ],
    );
  }

  /// 📍 Étape 2 : Localisation & Repères
  Widget _buildStep2Localisation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('bailleur_add_bien_step2_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(context.tr('bailleur_add_bien_step2_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 13)),

        const SizedBox(height: 20),

        if (_isLoadingGeo)
          const Center(child: CircularProgressIndicator())
        else ...[
          DropdownButtonFormField<VilleOption>(
            value: _selectedVille,
            decoration: InputDecoration(labelText: context.tr('bailleur_add_bien_ville_full_label'), prefixIcon: const Icon(Icons.location_city)),
            items: _villesDisponibles.map((v) {
              return DropdownMenuItem(value: v, child: Text(v.nom));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedVille = v);
                _chargerQuartiersPourVille(v.slug);
              }
            },
          ),

          const SizedBox(height: 16),

          if (!_useCustomQuartier && _quartiersDisponibles.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<QuartierOption>(
                  value: _selectedQuartier,
                  decoration: InputDecoration(labelText: context.tr('bailleur_add_bien_quartier_select_label'), prefixIcon: const Icon(Icons.map)),
                  items: _quartiersDisponibles.map((q) {
                    return DropdownMenuItem(value: q, child: Text(q.nom));
                  }).toList(),
                  onChanged: (q) {
                    if (q != null) setState(() => _selectedQuartier = q);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(context.tr('bailleur_add_bien_quartier_custom_button')),
                  onPressed: () => setState(() => _useCustomQuartier = true),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _quartierCustomCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('bailleur_add_bien_quartier_custom_label'),
                    hintText: context.tr('bailleur_add_bien_quartier_custom_hint'),
                    prefixIcon: const Icon(Icons.edit_location_alt),
                    suffixIcon: _quartiersDisponibles.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: () => setState(() => _useCustomQuartier = false),
                            tooltip: context.tr('bailleur_add_bien_quartier_back_to_list'),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(context.tr('bailleur_add_bien_quartier_custom_helper'), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
        ],

        const SizedBox(height: 16),

        TextFormField(
          controller: _repereCtrl,
          decoration: InputDecoration(
            labelText: context.tr('bailleur_add_bien_repere_label'),
            hintText: context.tr('bailleur_add_bien_repere_hint'),
            prefixIcon: const Icon(Icons.place),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _accesCtrl,
          decoration: InputDecoration(
            labelText: context.tr('bailleur_add_bien_access_full_label'),
            hintText: context.tr('bailleur_add_bien_access_hint'),
            prefixIcon: const Icon(Icons.directions),
          ),
        ),
      ],
    );
  }

  /// 📸 Étape 3 : Galerie Photo (Max 4 photos, SANS badges)
  Widget _buildStep3Photos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('bailleur_add_bien_step3_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_photosPaths.length} ${context.tr('bailleur_add_bien_photos_count_suffix')}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('bailleur_add_bien_step3_subtitle'),
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.photo_library, color: Colors.white),
            label: Text(context.tr('bailleur_add_bien_pick_gallery_button')),
            onPressed: _photosPaths.length >= 4 ? null : _pickImageFromGallery,
          ),
        ),

        const SizedBox(height: 20),

        if (_photosPaths.isEmpty)
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(context.tr('bailleur_add_bien_no_photos'), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _photosPaths.length,
            itemBuilder: (context, index) {
              final path = _photosPaths[index];
              final isNetwork = path.startsWith('http');

              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isNetwork
                          ? Image.network(path, fit: BoxFit.cover)
                          : Image.file(File(path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _retirerPhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// 💰 Étape 4 : Prix, Avance, Caution & Options
  Widget _buildStep4PrixEtValidation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('bailleur_add_bien_step4_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(context.tr('bailleur_add_bien_step4_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 13)),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _loyerCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('bailleur_add_bien_loyer_short_label'),
                  suffixText: 'FCFA',
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _chargesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('bailleur_add_bien_charges_short_label'),
                  suffixText: 'FCFA',
                  prefixIcon: const Icon(Icons.receipt_long),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SwitchListTile(
          title: Text(context.tr('bailleur_add_bien_charges_included')),
          value: _chargesIncluses,
          onChanged: (val) => setState(() => _chargesIncluses = val),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _avanceMois,
                decoration: InputDecoration(labelText: context.tr('bailleur_add_bien_avance_label')),
                items: [2, 3, 4, 5, 6].map((m) => DropdownMenuItem(value: m, child: Text('$m ${context.tr('bailleur_add_bien_mois_suffix')}'))).toList(),
                onChanged: (val) => setState(() => _avanceMois = val ?? 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _cautionMois,
                decoration: InputDecoration(labelText: context.tr('bailleur_add_bien_caution_label')),
                items: [1, 2, 3].map((m) => DropdownMenuItem(value: m, child: Text('$m ${context.tr('bailleur_add_bien_mois_suffix')}'))).toList(),
                onChanged: (val) => setState(() => _cautionMois = val ?? 1),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Column(
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _compteurEneo,
              decoration: InputDecoration(
                labelText: context.tr('bailleur_add_bien_compteur_eneo_label'),
                prefixIcon: const Icon(Icons.bolt),
              ),
              items: [
                DropdownMenuItem(value: 'INDIVIDUEL', child: Text(context.tr('bailleur_add_bien_compteur_individuel'), overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'COMMUN', child: Text(context.tr('bailleur_add_bien_compteur_commun'), overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'FORFAIT', child: Text(context.tr('bailleur_add_bien_compteur_forfait'), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _compteurEneo = val ?? 'INDIVIDUEL'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _compteurEau,
              decoration: InputDecoration(
                labelText: context.tr('bailleur_add_bien_source_eau_label'),
                prefixIcon: const Icon(Icons.water_drop),
              ),
              items: [
                DropdownMenuItem(value: 'CAMWATER', child: Text(context.tr('bailleur_add_bien_eau_camwater'), overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'FORAGE', child: Text(context.tr('bailleur_add_bien_eau_forage'), overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'PUITS', child: Text(context.tr('bailleur_add_bien_eau_puits'), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _compteurEau = val ?? 'CAMWATER'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SwitchListTile(
          title: Text(context.tr('bailleur_add_bien_meuble_label')),
          value: _meuble,
          onChanged: (val) => setState(() => _meuble = val),
        ),

        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'EAU_COURANTE',
            'GROUPE_ELECTROGENE',
            'PARKING',
            'CLOTURE',
            'GARDIEN',
            'CLIMATISATION',
            'BALCON',
          ].map((eq) {
            final selected = _equipementsSelectionnes.contains(eq);
            return FilterChip(
              label: Text(eq.replaceAll('_', ' ')),
              selected: selected,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              onSelected: (_) => _toggleEquipement(eq),
            );
          }).toList(),
        ),
      ],
    );
  }
}
