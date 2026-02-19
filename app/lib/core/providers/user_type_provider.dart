import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 유형 (소비자/리뷰어/업체)
enum UserType { consumer, reviewer, business }

/// 사용자 유형 상태 관리
class UserTypeNotifier extends StateNotifier<UserType> {
  UserTypeNotifier() : super(UserType.consumer) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final typeString = prefs.getString('user_type_preference');
    if (typeString != null) {
      state = UserType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => UserType.consumer,
      );
    }
  }

  Future<void> setUserType(UserType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type_preference', type.name);
  }
}

/// 사용자 유형 Provider
final userTypeProvider = StateNotifierProvider<UserTypeNotifier, UserType>((ref) {
  return UserTypeNotifier();
});

/// 사용자 유형이 선택되었는지 여부
final hasSelectedUserTypeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('user_type_preference');
});
