import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/alertes_repository.dart';
import '../models/alerte_model.dart';

final alertesRepositoryProvider = Provider((ref) => AlertesRepository());

class AlertesNotifier extends StateNotifier<List<AlerteModel>> {
  final AlertesRepository _repository;

  AlertesNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.fetchMesAlertes();
  }
}

final alertesProvider = StateNotifierProvider<AlertesNotifier, List<AlerteModel>>((ref) {
  return AlertesNotifier(ref.watch(alertesRepositoryProvider));
});
