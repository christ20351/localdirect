import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/document_model.dart';

class DocumentsRepository {
  final Dio _dio = ApiClient.dio;

  /// 📎 Soumettre un document (KYC compte ou preuve de propriété d'un bien) — POST /moi/documents
  Future<Map<String, dynamic>> soumettre({required String cheminFichier, required String type, String? bienId}) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        if (bienId != null) 'bienId': bienId,
        'fichier': await MultipartFile.fromFile(cheminFichier),
      });
      final response = await _dio.post(
        '/moi/documents',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return {'success': true, 'document': DocumentModel.fromJson(response.data as Map<String, dynamic>)};
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      return {'success': false, 'message': message is List ? message.join('\n') : (message ?? 'Échec de l\'envoi du document.')};
    }
  }

  /// 📋 Documents soumis par l'utilisateur connecté — GET /moi/documents
  Future<List<DocumentModel>> mesDocuments({String? bienId}) async {
    try {
      final response = await _dio.get('/moi/documents', queryParameters: {if (bienId != null) 'bienId': bienId});
      final List list = response.data;
      return list.map((json) => DocumentModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
