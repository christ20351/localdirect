import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/staff_models.dart';

class StaffRepository {
  final Dio _dio = ApiClient.dio;

  /// Récupère le fichier du document (via l'API protégée, pas d'URL publique) pour
  /// que le Staff voie réellement ce qui a été envoyé avant de valider ou rejeter.
  Future<Uint8List?> fetchDocumentImage(String documentId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/documents/$documentId/fichier',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } catch (_) {
      return null;
    }
  }

  Future<List<StaffDocumentModel>> fetchDocumentsEnAttente() async {
    try {
      final response = await _dio.get('/admin/documents', queryParameters: {'statut': 'EN_ATTENTE'});
      final List list = response.data;
      return list.map((json) => StaffDocumentModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> validerDocument(String id) async {
    try {
      await _dio.post('/admin/documents/$id/valider');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejeterDocument(String id, String motif) async {
    try {
      await _dio.post('/admin/documents/$id/rejeter', data: {'motif': motif});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<StaffBienModel>> fetchBiensEnAttente() async {
    try {
      final response = await _dio.get('/admin/biens', queryParameters: {'statut': 'EN_VERIFICATION'});
      final List list = response.data;
      return list.map((json) => StaffBienModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> validerBien(String id) async {
    try {
      await _dio.post('/admin/biens/$id/valider');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejeterBien(String id, String motif) async {
    try {
      await _dio.post('/admin/biens/$id/rejeter', data: {'motif': motif});
      return true;
    } catch (_) {
      return false;
    }
  }
}
