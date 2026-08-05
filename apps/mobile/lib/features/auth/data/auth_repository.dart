import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/constants.dart';

class AuthRepository {
  // Instance du client HTTP Dio pour émettre les requêtes REST vers l'API NestJS
  final Dio _dio = ApiClient.dio;

  // Stockage sécurisé pour conserver le jeton JWT dans la mémoire chiffrée du téléphone
  final _storage = const FlutterSecureStorage();

  // `serverClientId` = Web Client ID : c'est l'audience contre laquelle l'API
  // vérifie l'idToken renvoyé, y compris sur Android (voir AppConstants.googleWebClientId).
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: AppConstants.googleWebClientId.isNotEmpty ? AppConstants.googleWebClientId : null,
  );

  /// 🌐 Déclenche le vrai flux Google Sign-In (sélecteur de compte natif),
  /// récupère l'idToken et l'échange contre nos jetons JWT applicatifs.
  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (AppConstants.googleWebClientId.isEmpty) {
      return {
        'success': false,
        'message': 'Connexion Google pas encore configurée côté serveur.',
      };
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // L'utilisateur a fermé le sélecteur de compte sans choisir : pas une erreur.
        return {'success': false, 'cancelled': true};
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return {'success': false, 'message': 'Google n\'a pas renvoyé de jeton d\'identité.'};
      }

      return _connexionGoogle(idToken);
    } catch (e) {
      return {'success': false, 'message': 'Erreur Google Sign-In : $e'};
    }
  }

  /// Échange l'idToken Google contre nos jetons JWT applicatifs (POST /auth/google)
  Future<Map<String, dynamic>> _connexionGoogle(String idToken) async {
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
    bool devenirBailleur = false,
  }) async {
    try {
      final response = await _dio.post('/auth/inscription', data: {
        'nomComplet': nomComplet,
        'email': email,
        'telephone': telephone,
        'motDePasse': motDePasse,
        if (devenirBailleur) 'devenirBailleur': true,
      });

      final data = response.data;
      await _sauvegarderTokens(data['access_token'], data['refresh_token']);

      return {
        'success': true,
        'utilisateur': data['utilisateur'],
        'intentionBailleur': data['intentionBailleur'] == true,
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
    if (AppConstants.googleWebClientId.isNotEmpty) {
      await _googleSignIn.signOut();
    }
  }

  /// 🔑 Récupération du jeton d'accès stocké
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// 👤 Récupère le profil de l'utilisateur connecté (GET /auth/moi).
  /// Renvoie `null` si aucun jeton n'est stocké ou si l'appel échoue
  /// (jeton invalide/expiré et non rafraîchissable) — l'appelant doit alors
  /// traiter l'utilisateur comme non connecté.
  Future<Map<String, dynamic>?> getMoi() async {
    final token = await getAccessToken();
    if (token == null) return null;
    try {
      final response = await _dio.get('/auth/moi');
      return response.data as Map<String, dynamic>;
    } on DioException {
      return null;
    }
  }

  /// ✏️ Met à jour le profil (nom, email, langue, ville...) — PATCH /auth/profil
  Future<Map<String, dynamic>> updateProfil(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/auth/profil', data: data);
      return {'success': true, 'utilisateur': response.data as Map<String, dynamic>};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Échec de l\'enregistrement.'};
    }
  }

  /// 🏠 Ajoute le rôle Bailleur au compte connecté — POST /auth/devenir-bailleur
  /// Échoue tant que 2 documents de preuve de propriété n'ont pas été validés
  /// par le Staff (voir DocumentsRepository) : le message d'erreur réel du
  /// serveur est renvoyé pour guider l'utilisateur plutôt qu'un simple booléen.
  Future<Map<String, dynamic>> devenirBailleur() async {
    try {
      await _dio.post('/auth/devenir-bailleur');
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Échec de la demande.'};
    }
  }

  /// 🗑️ Supprime définitivement (côté serveur) le compte de l'utilisateur
  /// connecté, puis efface la session locale.
  Future<bool> supprimerCompte() async {
    try {
      await _dio.delete('/auth/moi');
      await deconnexion();
      return true;
    } on DioException {
      return false;
    }
  }
}
