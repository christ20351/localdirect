import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/visites_repository.dart';
import '../models/visit_model.dart';

final visitesRepositoryProvider = Provider((ref) => VisitesRepository());

class VisitesNotifier extends StateNotifier<List<VisitModel>> {
  final VisitesRepository _repository;

  VisitesNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.fetchMesVisites();
  }
}

final visitesProvider = StateNotifierProvider<VisitesNotifier, List<VisitModel>>((ref) {
  return VisitesNotifier(ref.watch(visitesRepositoryProvider));
});
