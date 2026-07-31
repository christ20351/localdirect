import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/bien_model.dart';
import '../models/bail_bailleur_model.dart';
import '../../candidatures/models/candidature_model.dart';

class BailleurRepository {
  final Dio _dio = ApiClient.dio;

  /// 🏘️ Biens du bailleur connecté — GET /moi/biens
  Future<List<BienModel>> fetchMesBiens() async {
    try {
      final response = await _dio.get('/moi/biens');
      final List list = response.data;
      return list.map((json) => BienModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// ➕ Créer un bien et son annonce — POST /biens
  Future<Map<String, dynamic>> creerBien(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/biens', data: data);
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message']) : null;
      return {
        'success': false,
        'message': message is List ? message.join('\n') : (message ?? 'Échec de la création du bien.'),
      };
    }
  }

  /// ✏️ Modifier un bien — PATCH /biens/:id
  Future<bool> modifierBien(String bienId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/biens/$bienId', data: data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ✅ Marquer un bien comme loué — POST /biens/:id/marquer-loue
  Future<bool> marquerLoue(String bienId) async {
    try {
      await _dio.post('/biens/$bienId/marquer-loue');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 📋 Dossiers de candidature reçus sur les biens du bailleur — GET /bailleur/candidatures
  Future<List<CandidatureModel>> fetchCandidaturesRecues() async {
    try {
      final response = await _dio.get('/bailleur/candidatures');
      final List list = response.data;
      return list.map((json) => CandidatureModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// ⚖️ Décider d'un dossier de candidature — POST /candidatures/:id/decider
  Future<Map<String, dynamic>> deciderCandidature(String candidatureId, {required bool accepter, String? motif}) async {
    try {
      await _dio.post('/candidatures/$candidatureId/decider', data: {
        'decision': accepter ? 'ACCEPTEE' : 'REFUSEE',
        if (motif != null && motif.isNotEmpty) 'motif': motif,
      });
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Échec du traitement du dossier.'};
    }
  }

  /// 📄 Baux du bailleur connecté (avec détail fiscal) — GET /bailleur/baux
  Future<List<BailBailleurModel>> fetchMesBaux() async {
    try {
      final response = await _dio.get('/bailleur/baux');
      final List list = response.data;
      return list.map((json) => BailBailleurModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
