import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/auth_response.dart';
import '../data/repositories/auth_repository.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth State
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.authenticated(UserModel user) => AuthState(
        isAuthenticated: true,
        user: user,
      );

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.error(String message) => AuthState(error: message);
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  // 앱 시작 시 인증 상태 확인
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();

    final hasToken = await _repository.hasToken();
    if (!hasToken) {
      state = AuthState.unauthenticated();
      return;
    }

    // 토큰 유효성 검증 API 호출
    final response = await _repository.verifyToken();
    if (response.success && response.user != null) {
      state = AuthState.authenticated(response.user!);
    } else {
      // 토큰이 유효하지 않으면 로그아웃 처리
      await _repository.logout();
      state = AuthState.unauthenticated();
    }
  }

  // 로그인
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.login(
      email: email,
      password: password,
    );

    if (response.success && response.user != null) {
      state = AuthState.authenticated(response.user!);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.errorMessage,
      );
      return false;
    }
  }

  // 회원가입
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String userType = 'consumer',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      userType: userType,
    );

    if (response.success && response.user != null) {
      state = AuthState.authenticated(response.user!);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.errorMessage,
      );
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  // 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 사용자 정보 업데이트
  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// 이메일 중복 확인 Provider
final emailAvailableProvider = FutureProvider.family<bool, String>((ref, email) async {
  if (email.isEmpty) return true;
  final repository = ref.watch(authRepositoryProvider);
  return repository.checkEmailAvailable(email);
});

// 휴대폰 번호 중복 확인 Provider
final phoneAvailableProvider = FutureProvider.family<bool, String>((ref, phone) async {
  if (phone.isEmpty) return true;
  final repository = ref.watch(authRepositoryProvider);
  return repository.checkPhoneAvailable(phone);
});
