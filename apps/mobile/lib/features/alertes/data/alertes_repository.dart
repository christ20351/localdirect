import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/alerte_model.dart';

class AlertesRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<AlerteModel>> fetchMesAlertes() async {
    try {
      final response = await _dio.get('/alertes');
      final List list = response.data;
      return list.map((json) => AlerteModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> creerAlerte({String? villeSlug, String? type, int? loyerMax}) async {
    try {
      await _dio.post('/alertes', data: {
        if (villeSlug != null) 'villeSlug': villeSlug,
        if (type != null) 'type': type,
        if (loyerMax != null) 'loyerMax': loyerMax,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supprimerAlerte(String id) async {
    try {
      await _dio.delete('/alertes/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> marquerVue(String id) async {
    try {
      await _dio.post('/alertes/$id/vu');
      return true;
    } catch (_) {
      return false;
    }
  }
}
