import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../properties/presentation/property_provider.dart';
import '../../documents/models/document_model.dart';
import '../../documents/presentation/document_upload_screen.dart';

import 'auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSaving = false;

  Future<void> _updateProfil(Map<String, dynamic> data) async {
    setState(() => _isSaving = true);
    final result = await ref.read(authRepositoryProvider).updateProfil(data);
    setState(() => _isSaving = false);
    if (!mounted) return;

    if (result['success'] == true) {
      ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('settings_saved')), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? context.tr('settings_save_error'))),
      );
    }
  }

  /// Change la langue à la fois côté serveur (persistance multi-appareil) et
  /// localement (effet immédiat sur toute l'app, sans redémarrer).
  Future<void> _changerLangue(String code) async {
    ref.read(localeProvider.notifier).setLanguageCode(code);
    await _updateProfil({'langue': code});
  }

  Future<void> _editNom(String nomActuel) async {
    final controller = TextEditingController(text: nomActuel);
    final nouveauNom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('settings_edit_name_title')),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: context.tr('register_name_label'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(context.tr('common_save'))),
        ],
      ),
    );
    if (nouveauNom != null && nouveauNom.isNotEmpty && nouveauNom != nomActuel) {
      await _updateProfil({'nomComplet': nouveauNom});
    }
  }

  Future<void> _editEmail(String emailActuel) async {
    final controller = TextEditingController(text: emailActuel);
    final nouvelEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('settings_edit_email_title')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: context.tr('register_email_label')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(context.tr('common_save'))),
        ],
      ),
    );
    if (nouvelEmail != null && nouvelEmail.isNotEmpty && nouvelEmail != emailActuel) {
      await _updateProfil({'email': nouvelEmail});
    }
  }

  /// Tente d'accorder le rôle Bailleur : le serveur vérifie qu'au moins 2 des 4
  /// documents de preuve de propriété ont été validés par le Staff. Si ce n'est
  /// pas encore le cas, on ouvre directement l'écran de soumission des documents
  /// plutôt que d'afficher une simple erreur.
  Future<void> _devenirBailleur() async {
    setState(() => _isSaving = true);
    final result = await ref.read(authRepositoryProvider).devenirBailleur();
    setState(() => _isSaving = false);
    if (!mounted) return;

    if (result['success'] == true) {
      ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('settings_become_landlord_success')), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? context.tr('settings_become_landlord_error'))));
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const DocumentUploadScreen(
          typesRequis: TypesDocuments.preuvePropriete,
          seuilRequis: TypesDocuments.seuilPreuvePropriete,
          titreKey: 'bailleur_kyc_title',
          sousTitreKey: 'bailleur_kyc_subtitle',
        ),
      ));
    }
  }

  Future<void> _confirmerSuppression() async {
    final premiereConfirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('settings_delete_account_title')),
        content: Text(context.tr('settings_delete_account_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('common_cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('common_continue'), style: const TextStyle(color: AppColors.crimson)),
          ),
        ],
      ),
    );
    if (premiereConfirmation != true) return;
    if (!mounted) return;

    final confirmationFinale = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('settings_delete_final_title')),
        content: Text(context.tr('settings_delete_final_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('common_cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('settings_delete_final_button')),
          ),
        ],
      ),
    );
    if (confirmationFinale != true) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    final success = await ref.read(authRepositoryProvider).supprimerCompte();
    setState(() => _isSaving = false);
    if (!mounted) return;

    if (success) {
      ref.invalidate(currentUserProvider);
      context.go('/auth/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('settings_delete_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDataSaver = ref.watch(dataSaverModeProvider);
    final villesAsync = ref.watch(villesListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(context.tr('settings_login_required')));
          }
          return AbsorbPointer(
            absorbing: _isSaving,
            child: Opacity(
              opacity: _isSaving ? 0.6 : 1,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _section(context.tr('settings_section_account')),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: AppColors.primary),
                          title: Text(context.tr('settings_full_name')),
                          subtitle: Text((user['nomComplet'] as String?) ?? context.tr('settings_not_provided')),
                          trailing: const Icon(Icons.edit_outlined, size: 18),
                          onTap: () => _editNom((user['nomComplet'] as String?) ?? ''),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                          title: Text(context.tr('settings_email')),
                          subtitle: Text((user['email'] as String?) ?? context.tr('settings_not_provided')),
                          trailing: const Icon(Icons.edit_outlined, size: 18),
                          onTap: () => _editEmail((user['email'] as String?) ?? ''),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                          title: Text(context.tr('settings_phone')),
                          subtitle: Text('${(user['telephone'] as String?) ?? '—'} · ${context.tr('settings_phone_note')}'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _section(context.tr('settings_section_language')),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.language_outlined, color: AppColors.primary),
                          title: Text(context.tr('settings_language')),
                          trailing: DropdownButton<String>(
                            value: (user['langue'] as String?) ?? 'FR',
                            underline: const SizedBox(),
                            items: [
                              DropdownMenuItem(value: 'FR', child: Text(context.tr('settings_language_fr'))),
                              DropdownMenuItem(value: 'EN', child: Text(context.tr('settings_language_en'))),
                            ],
                            onChanged: (val) {
                              if (val != null) _changerLangue(val);
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        villesAsync.when(
                          data: (villes) => ListTile(
                            leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                            title: Text(context.tr('settings_city')),
                            trailing: DropdownButton<String>(
                              value: villes.any((v) => v.id == user['villeId']) ? user['villeId'] as String : null,
                              hint: Text(context.tr('settings_city_choose')),
                              underline: const SizedBox(),
                              items: villes.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nom))).toList(),
                              onChanged: (val) {
                                if (val != null) _updateProfil({'villeId': val});
                              },
                            ),
                          ),
                          loading: () => ListTile(title: Text(context.tr('settings_cities_loading'))),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _section(context.tr('settings_section_display')),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(context.tr('settings_dark_theme')),
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.data_saver_on_outlined, color: AppColors.primary),
                          title: Text(context.tr('settings_data_saver')),
                          subtitle: Text(context.tr('settings_data_saver_subtitle'), style: const TextStyle(fontSize: 11)),
                          value: isDataSaver,
                          onChanged: (val) => ref.read(dataSaverModeProvider.notifier).state = val,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _section(context.tr('settings_section_locadirect_account')),
                  Card(
                    child: Builder(builder: (context) {
                      final roles = user['roles'] as List;
                      final estBailleur = roles.contains('BAILLEUR');

                      return Column(
                        children: [
                          if (estBailleur)
                            ListTile(
                              leading: const Icon(Icons.villa, color: AppColors.primary),
                              title: Text(context.tr('settings_landlord_active')),
                              subtitle: Text(context.tr('settings_landlord_active_subtitle'), style: const TextStyle(fontSize: 11)),
                            )
                          else
                            ListTile(
                              leading: const Icon(Icons.villa_outlined, color: AppColors.primary),
                              title: Text(context.tr('settings_become_landlord')),
                              subtitle: Text(context.tr('settings_become_landlord_subtitle'), style: const TextStyle(fontSize: 11)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _devenirBailleur,
                            ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _section(context.tr('settings_section_danger')),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline, color: AppColors.crimson),
                      title: Text(context.tr('settings_delete_account'), style: const TextStyle(color: AppColors.crimson)),
                      onTap: _confirmerSuppression,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(context.tr('settings_login_required'))),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}
