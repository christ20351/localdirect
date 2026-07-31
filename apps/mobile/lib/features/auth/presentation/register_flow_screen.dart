import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../properties/presentation/property_provider.dart';
import '../data/auth_repository.dart';

/// Inscription en 5 étapes : Intention → Identité → Téléphone & ville → Mot de
/// passe → Récapitulatif. Le compte est toujours créé avec le rôle LOCATAIRE
/// (seul rôle avec un parcours complet aujourd'hui) ; BAILLEUR peut être ajouté
/// dès l'inscription si l'utilisateur le souhaite (rôle léger, pas de KYC requis).
class RegisterFlowScreen extends ConsumerStatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  ConsumerState<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends ConsumerState<RegisterFlowScreen> {
  static const _totalSteps = 5;
  final _pageController = PageController();
  int _step = 0;

  final _identiteFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  VilleOption? _selectedVille;
  bool _devenirBailleur = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _submitError;

  final AuthRepository _authRepository = AuthRepository();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 1:
        return _identiteFormKey.currentState?.validate() ?? false;
      case 2:
        return _contactFormKey.currentState?.validate() ?? false;
      case 3:
        return _passwordFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  Future<void> _goNext() async {
    if (!_validateCurrentStep()) return;

    if (_step == _totalSteps - 1) {
      await _submit();
      return;
    }

    setState(() {
      _step++;
      _submitError = null;
    });
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _goBack() {
    if (_step == 0) {
      _retourVersLogin();
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  /// Revient à l'écran de connexion en dépilant si possible (cas normal :
  /// register a été atteint via `push` depuis login), sinon y navigue
  /// directement (cas d'un lien profond arrivé directement sur /auth/register).
  void _retourVersLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/login');
    }
  }

  Future<void> _submit() async {
    final rawPhone = _phoneController.text.trim();
    final formattedPhone = rawPhone.startsWith('+237') ? rawPhone : '+237$rawPhone';

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    final res = await _authRepository.inscription(
      nomComplet: _nameController.text.trim(),
      email: _emailController.text.trim(),
      telephone: formattedPhone,
      motDePasse: _passwordController.text,
      devenirBailleur: _devenirBailleur,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('register_success')),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/');
    } else {
      // On affiche la vraie erreur — plus de faux succès en cas d'échec.
      setState(() => _submitError = res['message'] ?? context.tr('register_error'));
    }
  }

  void _showAgentBientotDisponible() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('register_agent_dialog_title')),
        content: Text(context.tr('register_agent_dialog_body')),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('common_understood'))),
        ],
      ),
    );
  }

  String _stepOf(int n) => '${context.tr('register_step_prefix')} $n ${context.tr('register_step_of')} $_totalSteps';

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      scrollable: false,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
        title: Text(context.tr('register_title')),
      ),
      child: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildIntentionStep(),
                _buildIdentiteStep(),
                _buildContactStep(),
                _buildPasswordStep(),
                _buildRecapStep(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _goNext,
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_step == _totalSteps - 1 ? context.tr('register_create_account') : context.tr('common_next')),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.tr('register_already_account'), style: TextStyle(color: Colors.grey[400])),
              GestureDetector(
                onTap: _retourVersLogin,
                child: Text(context.tr('register_login_link'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : AppSpacing.xs),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        );
      }),
    );
  }

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildIntentionStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(context.tr('register_step1_title'), '${_stepOf(1)} — ${context.tr('register_step1_subtitle')}'),
          Card(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: Text(context.tr('register_search_home'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(context.tr('register_search_home_subtitle'), style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.check_circle, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: CheckboxListTile(
              secondary: const Icon(Icons.villa_outlined, color: AppColors.primary),
              title: Text(context.tr('register_also_owner')),
              subtitle: Text(context.tr('register_also_owner_subtitle'), style: const TextStyle(fontSize: 11)),
              value: _devenirBailleur,
              onChanged: (val) => setState(() => _devenirBailleur = val ?? false),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined, color: Colors.grey),
              title: Text(context.tr('register_become_agent')),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(context.tr('common_soon'), style: const TextStyle(fontSize: 10, color: AppColors.accentGold, fontWeight: FontWeight.bold)),
              ),
              onTap: _showAgentBientotDisponible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentiteStep() {
    return SingleChildScrollView(
      child: Form(
        key: _identiteFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(context.tr('register_step2_title'), '${_stepOf(2)} — ${context.tr('register_step2_subtitle')}'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.tr('register_name_label'), prefixIcon: const Icon(Icons.person_outline)),
              validator: (val) => (val == null || val.trim().isEmpty) ? context.tr('register_name_required') : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: context.tr('register_email_label'), prefixIcon: const Icon(Icons.email_outlined)),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return context.tr('register_email_required');
                if (!val.contains('@') || !val.contains('.')) return context.tr('register_email_invalid');
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    final villesAsync = ref.watch(villesListProvider);

    return SingleChildScrollView(
      child: Form(
        key: _contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(context.tr('register_step3_title'), '${_stepOf(3)} — ${context.tr('register_step3_subtitle')}'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr('register_phone_label'),
                prefixText: '+237 ',
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '6XXXXXXXX',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return context.tr('register_phone_required');
                final digits = val.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 9) return context.tr('register_phone_too_short');
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            villesAsync.when(
              data: (villes) => DropdownButtonFormField<VilleOption>(
                initialValue: _selectedVille,
                decoration: InputDecoration(labelText: context.tr('register_city_label'), prefixIcon: const Icon(Icons.location_city_outlined)),
                items: villes.map((v) => DropdownMenuItem(value: v, child: Text(v.nom))).toList(),
                onChanged: (val) => setState(() => _selectedVille = val),
                validator: (val) => val == null ? context.tr('register_city_required') : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(context.tr('register_cities_error'), style: const TextStyle(color: AppColors.crimson)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(context.tr('register_step4_title'), '${_stepOf(4)} — ${context.tr('register_step4_subtitle')}'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: context.tr('register_password_label'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) => (val == null || val.length < 6) ? context.tr('register_password_too_short') : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(labelText: context.tr('register_confirm_password_label'), prefixIcon: const Icon(Icons.lock_outline)),
              validator: (val) {
                if (val == null || val.isEmpty) return context.tr('register_confirm_password_required');
                if (val != _passwordController.text) return context.tr('register_password_mismatch');
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(context.tr('register_step5_title'), '${_stepOf(5)} — ${context.tr('register_step5_subtitle')}'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _recapRow(Icons.person_outline, _nameController.text.trim()),
                  const Divider(height: 20),
                  _recapRow(Icons.email_outlined, _emailController.text.trim()),
                  const Divider(height: 20),
                  _recapRow(Icons.phone_outlined, '+237 ${_phoneController.text.trim()}'),
                  const Divider(height: 20),
                  _recapRow(Icons.location_city_outlined, _selectedVille?.nom ?? '—'),
                  const Divider(height: 20),
                  _recapRow(
                    Icons.villa_outlined,
                    _devenirBailleur ? context.tr('register_recap_tenant_landlord') : context.tr('register_recap_tenant'),
                  ),
                ],
              ),
            ),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.crimson, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_submitError!, style: const TextStyle(color: AppColors.crimson, fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recapRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ],
    );
  }
}
