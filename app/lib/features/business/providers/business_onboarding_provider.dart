import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final businessOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('business_onboarding_completed') ?? false;
});
