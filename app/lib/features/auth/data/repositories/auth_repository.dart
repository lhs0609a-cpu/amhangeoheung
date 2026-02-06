import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/social_auth_service.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final SocialAuthService _socialAuthService = SocialAuthService();

  // 로그인
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.token != null) {
        await _apiClient.setToken(authResponse.token!);
      }

      return authResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 회원가입
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String userType = 'consumer',
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'userType': userType,
      });

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.token != null) {
        await _apiClient.setToken(authResponse.token!);
      }

      return authResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _apiClient.clearToken();
  }

  // 토큰 갱신
  Future<AuthResponse> refreshToken(String token) async {
    try {
      final response = await _apiClient.post('/auth/refresh', data: {
        'token': token,
      });

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.token != null) {
        await _apiClient.setToken(authResponse.token!);
      }

      return authResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 이메일 중복 확인
  Future<bool> checkEmailAvailable(String email) async {
    try {
      final response = await _apiClient.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      return response.data['available'] ?? false;
    } catch (_) {
      return false;
    }
  }

  // 휴대폰 번호 중복 확인
  Future<bool> checkPhoneAvailable(String phone) async {
    try {
      final response = await _apiClient.get(
        '/auth/check-phone',
        queryParameters: {'phone': phone},
      );
      return response.data['available'] ?? false;
    } catch (_) {
      return false;
    }
  }

  // 토큰 존재 여부 확인
  Future<bool> hasToken() async {
    return await _apiClient.hasToken();
  }

  // 토큰 유효성 검증 및 사용자 정보 조회
  Future<AuthResponse> verifyToken() async {
    try {
      final response = await _apiClient.get('/auth/verify');
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      // 401 에러면 토큰 만료
      if (e.response?.statusCode == 401) {
        await _apiClient.clearToken();
        return AuthResponse(
          success: false,
          message: '세션이 만료되었습니다. 다시 로그인해주세요.',
        );
      }
      return _handleDioError(e);
    }
  }

  // 소셜 로그인
  Future<AuthResponse> socialLogin(SocialProvider provider) async {
    try {
      // 1. 소셜 로그인 수행
      final socialResult = await _socialAuthService.signIn(provider);

      if (!socialResult.success || socialResult.userInfo == null) {
        return AuthResponse(
          success: false,
          message: socialResult.errorMessage ?? '소셜 로그인에 실패했습니다.',
        );
      }

      // 2. 백엔드에 소셜 로그인 정보 전송
      final response = await _apiClient.post('/auth/social-login', data: {
        'provider': socialResult.userInfo!.provider.name,
        'providerId': socialResult.userInfo!.providerId,
        'email': socialResult.userInfo!.email,
        'name': socialResult.userInfo!.name,
        'profileImage': socialResult.userInfo!.profileImage,
        'idToken': socialResult.userInfo!.idToken,
        'accessToken': socialResult.userInfo!.accessToken,
      });

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.token != null) {
        await _apiClient.setToken(authResponse.token!);
      }

      return authResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: '소셜 로그인 중 오류가 발생했습니다.',
      );
    }
  }

  // Google 로그인
  Future<AuthResponse> googleLogin() => socialLogin(SocialProvider.google);

  // Apple 로그인
  Future<AuthResponse> appleLogin() => socialLogin(SocialProvider.apple);

  // 카카오 로그인
  Future<AuthResponse> kakaoLogin() => socialLogin(SocialProvider.kakao);

  // 소셜 로그아웃 (소셜 세션만 클리어)
  Future<void> socialLogout() async {
    await _socialAuthService.signOutAll();
  }

  AuthResponse _handleDioError(DioException e) {
    if (e.response != null) {
      return AuthResponse.fromJson(e.response!.data);
    }

    String message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '서버 연결 시간이 초과되었습니다.';
        break;
      case DioExceptionType.connectionError:
        message = '네트워크 연결을 확인해주세요.';
        break;
      default:
        message = '서버 오류가 발생했습니다.';
    }

    return AuthResponse(success: false, message: message);
  }
}
