import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/candidatures_repository.dart';
import '../models/candidature_model.dart';

final candidaturesRepositoryProvider = Provider((ref) => CandidaturesRepository());

class CandidaturesNotifier extends StateNotifier<List<CandidatureModel>> {
  final CandidaturesRepository _repository;

  CandidaturesNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.fetchMesCandidatures();
  }

  bool aUneCandidaturePour(String annonceId) => state.any((c) => c.annonceId == annonceId);

  CandidatureModel? candidaturePour(String annonceId) {
    try {
      return state.firstWhere((c) => c.annonceId == annonceId);
    } catch (_) {
      return null;
    }
  }
}

final candidaturesProvider = StateNotifierProvider<CandidaturesNotifier, List<CandidatureModel>>((ref) {
  return CandidaturesNotifier(ref.watch(candidaturesRepositoryProvider));
});
