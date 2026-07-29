import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Contrôleur pour gérer le changement d'onglet (OTP vs Email/Mot de passe)
  late TabController _tabController;

  // Repository pour déclencher les requêtes vers le backend NestJS
  final AuthRepository _authRepository = AuthRepository();

  // Contrôleurs de saisie des champs de texte
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Indicateur d'état de chargement lors d'un appel réseau
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 📲 Soumission du numéro de téléphone pour recevoir le code OTP
  Future<void> _handleOtpSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre numéro de téléphone.')),
      );
      return;
    }

    final formattedPhone = phone.startsWith('+237') ? phone : '+237$phone';

    setState(() => _isLoading = true);
    final res = await _authRepository.demanderOtp(formattedPhone);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      context.go('/auth/otp-verify', extra: {
        'telephone': formattedPhone,
        'debugCode': res['debugCode'],
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Erreur OTP')),
      );
    }
  }

  /// 🔑 Soumission de la connexion par Email / Mot de passe
  Future<void> _handlePasswordSubmit() async {
    final identifiant = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifiant.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir l\'identifiant et le mot de passe.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authRepository.connexion(identifiant, password);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Erreur de connexion')),
      );
    }
  }

  /// 🌐 Soumission de la connexion Google Sign-In
  Future<void> _handleGoogleSubmit() async {
    // TODO: Appel du SDK google_sign_in pour obtenir le idToken réel sur Android/iOS
    const mockIdToken = 'mock_google_id_token_2026';

    setState(() => _isLoading = true);
    final res = await _authRepository.connexionGoogle(mockIdToken);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Échec connexion Google')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // En-tête avec Logo et Nom de l'application
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'LocaDirect CM',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Plateforme immobilière certifiée au Cameroun',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),

              const SizedBox(height: 20),

              // Bouton Connexion Google
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.darkBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.redAccent),
                label: const Text(
                  'Continuer avec Google',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                onPressed: _isLoading ? null : _handleGoogleSubmit,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.darkBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OU', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ),
                  const Expanded(child: Divider(color: AppColors.darkBorder)),
                ],
              ),

              const SizedBox(height: 20),

              // Barre d'onglets (SMS OTP vs Email)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: '📱 Téléphone OTP'),
                    Tab(text: '📧 Email & Pass'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet 1 : Authentification OTP Téléphone
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connexion rapide par SMS / WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Entrez votre numéro camerounais pour recevoir un code d\'accès à 4 chiffres.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de téléphone',
                            prefixText: '+237 ',
                            hintText: '6XXXXXXXX',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleOtpSubmit,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Recevoir le Code OTP'),
                          ),
                        ),
                      ],
                    ),

                    // Onglet 2 : Authentification Email & Mot de passe
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connexion par Email / Mot de passe',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email ou Téléphone',
                              hintText: 'exemple@locadirect.cm',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handlePasswordSubmit,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Se Connecter'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Pas encore de compte ? ', style: TextStyle(color: Colors.grey[400])),
                              GestureDetector(
                                onTap: () => context.go('/auth/register'),
                                child: const Text(
                                  'S\'inscrire',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
