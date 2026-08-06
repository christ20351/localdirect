import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/visit_model.dart';

class VisitesRepository {
  final Dio _dio = ApiClient.dio;

  /// 📅 Demander une visite sur une annonce — POST /annonces/:id/visites
  Future<Map<String, dynamic>> demanderVisite(String annonceId, {DateTime? creneauSouhaite}) async {
    try {
      final response = await _dio.post('/annonces/$annonceId/visites', data: {
        if (creneauSouhaite != null) 'creneauSouhaite': creneauSouhaite.toIso8601String(),
      });
      return {'success': true, 'visite': VisitModel.fromJson(response.data as Map<String, dynamic>)};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Impossible de créer la demande de visite.'};
    }
  }

  /// ✅ Confirmer que le bien correspond à l'annonce — POST /visites/:id/confirmer
  Future<Map<String, dynamic>> confirmerVisite(String visiteId) async {
    try {
      final response = await _dio.post('/visites/$visiteId/confirmer');
      return {'success': true, 'visite': VisitModel.fromJson(response.data as Map<String, dynamic>)};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Échec de la confirmation.'};
    }
  }

  /// ⚠️ Signaler un problème (bien indisponible, non conforme...) — POST /visites/:id/contester
  Future<Map<String, dynamic>> contesterVisite(String visiteId, {required String motif, String? details}) async {
    try {
      final response = await _dio.post('/visites/$visiteId/contester', data: {
        'motif': motif,
        if (details != null && details.isNotEmpty) 'details': details,
      });
      return {'success': true, 'visite': VisitModel.fromJson(response.data as Map<String, dynamic>)};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Échec du signalement.'};
    }
  }

  /// 📋 Visites du locataire connecté — GET /moi/visites
  Future<List<VisitModel>> fetchMesVisites() async {
    try {
      final response = await _dio.get('/moi/visites');
      final List list = response.data;
      return list.map((json) => VisitModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
