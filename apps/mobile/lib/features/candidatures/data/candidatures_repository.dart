import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/candidature_model.dart';

class CandidaturesRepository {
  final Dio _dio = ApiClient.dio;

  /// 📋 Soumettre un dossier de candidature — POST /annonces/:id/candidatures
  Future<Map<String, dynamic>> soumettreCandidature(
    String annonceId, {
    int? revenuDeclare,
    String? sourceRevenu,
    int? nbOccupants,
    String? message,
    String? garantNomComplet,
    String? garantTelephone,
    String? garantProfession,
    String? garantLien,
  }) async {
    try {
      final response = await _dio.post('/annonces/$annonceId/candidatures', data: {
        if (revenuDeclare != null) 'revenuDeclare': revenuDeclare,
        if (sourceRevenu != null) 'sourceRevenu': sourceRevenu,
        if (nbOccupants != null) 'nbOccupants': nbOccupants,
        if (message != null && message.isNotEmpty) 'message': message,
        if (garantNomComplet != null && garantNomComplet.isNotEmpty) 'garantNomComplet': garantNomComplet,
        if (garantTelephone != null && garantTelephone.isNotEmpty) 'garantTelephone': garantTelephone,
        if (garantProfession != null && garantProfession.isNotEmpty) 'garantProfession': garantProfession,
        if (garantLien != null && garantLien.isNotEmpty) 'garantLien': garantLien,
      });
      return {'success': true, 'candidature': CandidatureModel.fromJson(response.data as Map<String, dynamic>)};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Échec de l\'envoi du dossier.'};
    }
  }

  /// 📋 Dossiers du locataire connecté — GET /moi/candidatures
  Future<List<CandidatureModel>> fetchMesCandidatures() async {
    try {
      final response = await _dio.get('/moi/candidatures');
      final List list = response.data;
      return list.map((json) => CandidatureModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
