import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/staff_repository.dart';
import '../models/staff_models.dart';

final staffRepositoryProvider = Provider((ref) => StaffRepository());

class DocumentsEnAttenteNotifier extends StateNotifier<List<StaffDocumentModel>> {
  final StaffRepository _repository;
  DocumentsEnAttenteNotifier(this._repository) : super([]) {
    refresh();
  }
  Future<void> refresh() async => state = await _repository.fetchDocumentsEnAttente();
}

final documentsEnAttenteProvider = StateNotifierProvider<DocumentsEnAttenteNotifier, List<StaffDocumentModel>>((ref) {
  return DocumentsEnAttenteNotifier(ref.watch(staffRepositoryProvider));
});

class BiensEnAttenteNotifier extends StateNotifier<List<StaffBienModel>> {
  final StaffRepository _repository;
  BiensEnAttenteNotifier(this._repository) : super([]) {
    refresh();
  }
  Future<void> refresh() async => state = await _repository.fetchBiensEnAttente();
}

final biensEnAttenteProvider = StateNotifierProvider<BiensEnAttenteNotifier, List<StaffBienModel>>((ref) {
  return BiensEnAttenteNotifier(ref.watch(staffRepositoryProvider));
});
