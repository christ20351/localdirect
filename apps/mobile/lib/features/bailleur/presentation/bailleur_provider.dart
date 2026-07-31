import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bailleur_repository.dart';
import '../models/bien_model.dart';
import '../models/bail_bailleur_model.dart';
import '../../candidatures/models/candidature_model.dart';

final bailleurRepositoryProvider = Provider((ref) => BailleurRepository());

class MesBiensNotifier extends StateNotifier<List<BienModel>> {
  final BailleurRepository _repository;

  MesBiensNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.fetchMesBiens();
  }
}

final mesBiensProvider = StateNotifierProvider<MesBiensNotifier, List<BienModel>>((ref) {
  return MesBiensNotifier(ref.watch(bailleurRepositoryProvider));
});

class CandidaturesRecuesNotifier extends StateNotifier<List<CandidatureModel>> {
  final BailleurRepository _repository;

  CandidaturesRecuesNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.fetchCandidaturesRecues();
  }
}

final candidaturesRecuesProvider = StateNotifierProvider<CandidaturesRecuesNotifier, List<CandidatureModel>>((ref) {
  return CandidaturesRecuesNotifier(ref.watch(bailleurRepositoryProvider));
});

class MesBauxBailleurNotifier extends StateNotifier<List<BailBailleurModel>> {
  final BailleurRepository _repository;

  MesBauxBailleurNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.fetchMesBaux();
  }
}

final mesBauxBailleurProvider = StateNotifierProvider<MesBauxBailleurNotifier, List<BailBailleurModel>>((ref) {
  return MesBauxBailleurNotifier(ref.watch(bailleurRepositoryProvider));
});
