import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/season_model.dart';
import '../data/repositories/season_repository.dart';

final seasonRepositoryProvider = Provider((ref) => SeasonRepository());

final activeSeasonsProvider = FutureProvider<List<SeasonModel>>((ref) async {
  final repository = ref.read(seasonRepositoryProvider);
  return repository.getActiveSeasons();
});
