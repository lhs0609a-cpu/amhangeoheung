import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// 인증 만료 이벤트를 전달하기 위한 StreamController
class AuthEventBus {
  static final AuthEventBus _instance = AuthEventBus._internal();
  factory AuthEventBus() => _instance;
  AuthEventBus._internal();

  final _authExpiredController = StreamController<void>.broadcast();

  Stream<void> get onAuthExpired => _authExpiredController.stream;

  void notifyAuthExpired() {
    _authExpiredController.add(null);
  }

  void dispose() {
    _authExpiredController.close();
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  /// `ApiClient.instance.dio` 형태로 쓰는 호출부를 위한 별칭.
  static ApiClient get instance => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthEventBus _authEventBus = AuthEventBus();

  /// 토큰 갱신 동시 요청 방지를 위한 락
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  /// 토큰 갱신 대상이 아닌 경로 (무한 루프 방지)
  /// baseUrl에 이미 '/api'가 포함되므로 여기서는 '/api'를 붙이지 않는다.
  static const String _refreshTokenPath = '/auth/refresh';

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final requestPath = error.requestOptions.path;

          // 토큰 갱신 요청 자체가 401이면 무한 루프 방지 - 바로 로그아웃
          if (requestPath == _refreshTokenPath) {
            await _handleAuthExpired();
            return handler.next(error);
          }

          // 자동 토큰 갱신 시도
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            // 갱신 성공: 새 토큰으로 원래 요청 재시도
            try {
              final newToken =
                  await _storage.read(key: AppConstants.tokenKey);
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';

              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          } else {
            // 갱신 실패: 인증 만료 처리
            await _handleAuthExpired();
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// 토큰 갱신 시도 (동시 요청 시 락으로 보호)
  Future<bool> _attemptTokenRefresh() async {
    // 이미 갱신 중이면 진행 중인 갱신 완료를 대기
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final currentToken =
          await _storage.read(key: AppConstants.tokenKey);
      if (currentToken == null) {
        _completeRefresh(false);
        return false;
      }

      final response = await _dio.post(
        _refreshTokenPath,
        data: {'token': currentToken},
      );

      if (response.statusCode == 200 &&
          response.data?['success'] == true &&
          response.data?['data']?['token'] != null) {
        final newToken = response.data['data']['token'] as String;
        await _storage.write(key: AppConstants.tokenKey, value: newToken);
        _completeRefresh(true);
        return true;
      } else {
        _completeRefresh(false);
        return false;
      }
    } on DioException {
      _completeRefresh(false);
      return false;
    } catch (_) {
      _completeRefresh(false);
      return false;
    }
  }

  /// 갱신 락 해제 및 대기 중인 요청에 결과 전달
  void _completeRefresh(bool success) {
    _isRefreshing = false;
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete(success);
    }
    _refreshCompleter = null;
  }

  /// 인증 만료 처리: 토큰 삭제 후 로그아웃 이벤트 발생
  Future<void> _handleAuthExpired() async {
    await _storage.delete(key: AppConstants.tokenKey);
    _authEventBus.notifyAuthExpired();
  }

  /// 인증 만료 이벤트 스트림
  Stream<void> get onAuthExpired => _authEventBus.onAuthExpired;

  Dio get dio => _dio;

  // 토큰 저장
  Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  // 토큰 삭제
  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // 토큰 확인
  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  // GET 요청
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // POST 요청
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  // PUT 요청
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  // DELETE 요청
  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }

  /// DioException 등에서 백엔드의 사용자용 에러 메시지를 추출한다.
  /// 응답 형식: { success, message } 또는 { success, error: { message } }
  static String? extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final err = data['error'];
        if (err is Map && err['message'] is String) {
          return err['message'] as String;
        }
        if (data['message'] is String) {
          return data['message'] as String;
        }
      }
    }
    return null;
  }

  // 파일 업로드
  Future<Response> uploadFile(String path, String filePath, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData);
  }
}
