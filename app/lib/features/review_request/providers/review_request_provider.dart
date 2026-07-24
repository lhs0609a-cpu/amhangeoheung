import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/review_request_repository.dart';

final reviewRequestRepositoryProvider = Provider((ref) => ReviewRequestRepository());

final popularRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.read(reviewRequestRepositoryProvider);
  return repository.getPopularRequests();
});
