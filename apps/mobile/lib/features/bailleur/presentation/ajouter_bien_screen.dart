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
        const SnackBar(content: Text('Limite de 4 photos maximum atteinte.')),
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
      _ajouterDemoImageFallback();
    }
  }

  void _ajouterDemoImageFallback() {
    if (_photosPaths.length >= 4) return;
    final demoUrls = [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=80',
    ];
    setState(() {
      _photosPaths.add(demoUrls[_photosPaths.length % demoUrls.length]);
    });
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
    final loyerXAF = int.tryParse(_loyerCtrl.text.trim()) ?? 0;
    final chargesXAF = int.tryParse(_chargesCtrl.text.trim()) ?? 0;

    final customQuartier = _quartierCustomCtrl.text.trim();
    final quartierFinal = customQuartier.isNotEmpty
        ? customQuartier
        : (_selectedQuartier?.nom ?? '');

    final payload = {
      'titre': _titreCtrl.text.trim().isEmpty ? 'Annonce $_typeBien' : _titreCtrl.text.trim(),
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
      'photos': _photosPaths,
    };

    setState(() => _isSubmitting = true);

    bool isSuccess = false;
    String message = '';

    if (widget.bienToEdit != null) {
      isSuccess = await ref.read(bailleurRepositoryProvider).modifierBien(widget.bienToEdit!.id, payload);
      message = isSuccess ? 'Bien et photos mis à jour avec succès !' : 'Erreur de modification.';
    } else {
      final res = await ref.read(bailleurRepositoryProvider).creerBien(payload);
      isSuccess = (res['success'] == true);
      message = res['message'] ?? 'Bien publié avec succès !';
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
        title: Text(isEdit ? 'Modifier le Bien' : context.tr('bailleur_add_bien_title')),
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
                        'Étape ${_currentStep + 1} sur 4',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                      Text(
                        _currentStep == 0
                            ? '1. Général'
                            : _currentStep == 1
                                ? '2. Localisation'
                                : _currentStep == 2
                                    ? '3. Photos'
                                    : '4. Prix & Options',
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
                        child: const Text('Précédent'),
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
                          : Text(_currentStep < 3 ? 'Suivant ➔' : (isEdit ? 'Enregistrer tout' : 'Publier mon Bien')),
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
        const Text('Étape 1 : Type & Identité du bien', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Sélectionnez la catégorie de votre logement.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _typeBien,
          decoration: const InputDecoration(labelText: 'Type de bien', prefixIcon: Icon(Icons.home_work)),
          items: const [
            DropdownMenuItem(value: 'STUDIO', child: Text('Studio Moderne')),
            DropdownMenuItem(value: 'APPARTEMENT', child: Text('Appartement')),
            DropdownMenuItem(value: 'CHAMBRE_MODERNE', child: Text('Chambre Moderne')),
            DropdownMenuItem(value: 'CHAMBRE_SIMPLE', child: Text('Chambre Simple')),
            DropdownMenuItem(value: 'DUPLEX', child: Text('Duplex')),
            DropdownMenuItem(value: 'MAISON', child: Text('Maison / Villa')),
            DropdownMenuItem(value: 'BOUTIQUE', child: Text('Boutique / Bureau')),
          ],
          onChanged: (val) => setState(() => _typeBien = val ?? 'STUDIO'),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _titreCtrl,
          decoration: InputDecoration(
            labelText: context.tr('bailleur_add_bien_titre_label'),
            hintText: 'Ex: Studio Moderne Climatisé avec Balcon',
            prefixIcon: const Icon(Icons.title),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description détaillée du bien',
            hintText: 'Décrivez l\'aménagement, le calme du quartier, la proximité des transports...',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    );
  }

  /// 📍 Étape 2 : Localisation & Repères
  Widget _buildStep2Localisation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 2 : Localisation & Repères', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Indiquez la ville et le quartier exacts.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),

        const SizedBox(height: 20),

        if (_isLoadingGeo)
          const Center(child: CircularProgressIndicator())
        else ...[
          DropdownButtonFormField<VilleOption>(
            value: _selectedVille,
            decoration: const InputDecoration(labelText: 'Ville (Cameroun)', prefixIcon: Icon(Icons.location_city)),
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
                  decoration: const InputDecoration(labelText: 'Sélectionnez le quartier', prefixIcon: Icon(Icons.map)),
                  items: _quartiersDisponibles.map((q) {
                    return DropdownMenuItem(value: q, child: Text(q.nom));
                  }).toList(),
                  onChanged: (q) {
                    if (q != null) setState(() => _selectedQuartier = q);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Saisir le nom d\'un autre quartier'),
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
                    labelText: 'Nom du Quartier (Saisie Libre)',
                    hintText: 'Ex: Bonapriso, Ndogpassi, Melen...',
                    prefixIcon: const Icon(Icons.edit_location_alt),
                    suffixIcon: _quartiersDisponibles.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: () => setState(() => _useCustomQuartier = false),
                            tooltip: 'Revenir à la liste',
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Saisissez librement n\'importe quel nom de quartier au Cameroun.', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
        ],

        const SizedBox(height: 16),

        TextFormField(
          controller: _repereCtrl,
          decoration: const InputDecoration(
            labelText: 'Point de repère principal',
            hintText: 'Ex: Carrefour Camico / Station Total Makèpè',
            prefixIcon: Icon(Icons.place),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _accesCtrl,
          decoration: const InputDecoration(
            labelText: 'Indications d\'accès (Masquées au public)',
            hintText: 'Ex: Entrée après la pharmacie, portail vert',
            prefixIcon: Icon(Icons.directions),
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
            const Text('Étape 3 : Photos du Logement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_photosPaths.length} / 4 photos',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Sélectionnez jusqu\'à 4 photos nettes depuis votre galerie mobile.',
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
            label: const Text('Sélectionner depuis ma Galerie Photo'),
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Aucune photo ajoutée', style: TextStyle(color: Colors.grey)),
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
        const Text('Étape 4 : Prix, Caution & Équipements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Définissez vos conditions de loyer et compteurs.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _loyerCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Loyer mensuel',
                  suffixText: 'FCFA',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _chargesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Charges',
                  suffixText: 'FCFA',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Charges incluses dans le loyer'),
          value: _chargesIncluses,
          onChanged: (val) => setState(() => _chargesIncluses = val),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _avanceMois,
                decoration: const InputDecoration(labelText: 'Avance (mois)'),
                items: [2, 3, 4, 5, 6].map((m) => DropdownMenuItem(value: m, child: Text('$m mois'))).toList(),
                onChanged: (val) => setState(() => _avanceMois = val ?? 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _cautionMois,
                decoration: const InputDecoration(labelText: 'Caution (mois)'),
                items: [1, 2, 3].map((m) => DropdownMenuItem(value: m, child: Text('$m mois'))).toList(),
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
              decoration: const InputDecoration(
                labelText: 'Compteur Électricité (ENEO)',
                prefixIcon: Icon(Icons.bolt),
              ),
              items: const [
                DropdownMenuItem(value: 'INDIVIDUEL', child: Text('Individuel (Propre compteur)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'COMMUN', child: Text('Décompteur Commun', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'FORFAIT', child: Text('Forfait mensuel inclus', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _compteurEneo = val ?? 'INDIVIDUEL'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _compteurEau,
              decoration: const InputDecoration(
                labelText: 'Source d\'eau',
                prefixIcon: Icon(Icons.water_drop),
              ),
              items: const [
                DropdownMenuItem(value: 'CAMWATER', child: Text('Camwater (Robinet)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'FORAGE', child: Text('Forage / Château d\'eau', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'PUITS', child: Text('Puits aménagé', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _compteurEau = val ?? 'CAMWATER'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SwitchListTile(
          title: const Text('Logement Meublé'),
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
