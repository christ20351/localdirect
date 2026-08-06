import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/documents_repository.dart';
import '../models/document_model.dart';

final documentsRepositoryProvider = Provider((ref) => DocumentsRepository());

class MesDocumentsNotifier extends StateNotifier<List<DocumentModel>> {
  final DocumentsRepository _repository;
  final String? bienId;

  MesDocumentsNotifier(this._repository, {this.bienId}) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.mesDocuments(bienId: bienId);
  }
}

/// Documents de KYC de compte (bienId == null) : preuve de propriété bailleur ou KYC agent.
final mesDocumentsCompteProvider = StateNotifierProvider<MesDocumentsNotifier, List<DocumentModel>>((ref) {
  return MesDocumentsNotifier(ref.watch(documentsRepositoryProvider));
});
