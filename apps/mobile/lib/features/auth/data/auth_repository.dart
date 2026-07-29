import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  // Instance du client HTTP Dio pour émettre les requêtes REST vers l'API NestJS
  final Dio _dio = ApiClient.dio;

  // Stockage sécurisé pour conserver le jeton JWT dans la mémoire chiffrée du téléphone
  final _storage = const FlutterSecureStorage();

  /// 📲 Demande d'envoi de code OTP (SMS ou WhatsApp)
  Future<Map<String, dynamic>> demanderOtp(String telephone, {String canal = 'SMS'}) async {
    try {
      final response = await _dio.post('/auth/otp/demander', data: {
        'telephone': telephone,
        'canal': canal,
      });
      return {
        'success': true,
        'message': response.data['message'],
        'debugCode': response.data['debugCode'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la demande d\'OTP',
      };
    }
  }

  /// 🔐 Vérification du code OTP saisi par l'utilisateur
  Future<Map<String, dynamic>> verifierOtp(String telephone, String code) async {
    try {
      final response = await _dio.post('/auth/otp/verifier', data: {
        'telephone': telephone,
        'code': code,
      });

      final data = response.data;
      await _sauvegarderTokens(data['access_token'], data['refresh_token']);

      return {
        'success': true,
        'utilisateur': data['utilisateur'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Code OTP incorrect',
      };
    }
  }

  /// 🌐 Connexion / Inscription via Google Sign-In
  Future<Map<String, dynamic>> connexionGoogle(String idToken) async {
    try {
      final response = await _dio.post('/auth/google', data: {
        'idToken': idToken,
      });

      final data = response.data;
      await _sauvegarderTokens(data['access_token'], data['refresh_token']);

      return {
        'success': true,
        'utilisateur': data['utilisateur'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur de connexion Google',
      };
    }
  }

  /// 📧 Inscription complète par Email + Mot de passe + Téléphone
  Future<Map<String, dynamic>> inscription({
    required String nomComplet,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    try {
      final response = await _dio.post('/auth/inscription', data: {
        'nomComplet': nomComplet,
        'email': email,
        'telephone': telephone,
        'motDePasse': motDePasse,
      });

      final data = response.data;
      await _sauvegarderTokens(data['access_token'], data['refresh_token']);

      return {
        'success': true,
        'utilisateur': data['utilisateur'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de l\'inscription',
      };
    }
  }

  /// 🔑 Connexion par Email/Téléphone + Mot de passe
  Future<Map<String, dynamic>> connexion(String identifiant, String motDePasse) async {
    try {
      final response = await _dio.post('/auth/connexion', data: {
        'identifiant': identifiant,
        'motDePasse': motDePasse,
      });

      final data = response.data;
      await _sauvegarderTokens(data['access_token'], data['refresh_token']);

      return {
        'success': true,
        'utilisateur': data['utilisateur'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Identifiant ou mot de passe incorrect',
      };
    }
  }

  /// 💾 Sauvegarde sécurisée des jetons JWT dans le stockage chiffré du téléphone
  Future<void> _sauvegarderTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  /// 🚪 Déconnexion de l'utilisateur
  Future<void> deconnexion() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  /// 🔑 Récupération du jeton d'accès stocké
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
}
