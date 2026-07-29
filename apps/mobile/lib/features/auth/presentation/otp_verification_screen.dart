import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String telephone;
  final String? debugCode;

  const OtpVerificationScreen({
    super.key,
    required this.telephone,
    this.debugCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir les 4 chiffres du code OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authRepository.verifierOtp(widget.telephone, code);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Code OTP incorrect')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code envoyé au ${widget.telephone}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Saisissez le code à 4 chiffres reçu par SMS ou WhatsApp.',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),

            if (widget.debugCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Text(
                      'Code de test (Dev) : ${widget.debugCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '• • • •',
                counterText: '',
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Valider et Accéder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
