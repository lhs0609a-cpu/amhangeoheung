import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/hwahae_colors.dart';
import '../theme/hwahae_typography.dart';

/// Edge Case Handler
/// 네트워크 오류, 중복 제출, 세션 만료 등 엣지 케이스 처리
class EdgeCaseHandler {
  static final EdgeCaseHandler _instance = EdgeCaseHandler._internal();
  factory EdgeCaseHandler() => _instance;
  EdgeCaseHandler._internal();

  // 중복 제출 방지를 위한 진행 중인 요청 추적
  final Set<String> _pendingRequests = {};

  // 디바운스 타이머
  final Map<String, Timer> _debounceTimers = {};

  // 스로틀 타임스탬프
  final Map<String, DateTime> _throttleTimestamps = {};

  /// 네트워크 연결 상태 확인
  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// 네트워크 연결 스트림
  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }

  /// 중복 제출 방지 래퍼
  /// [requestId]: 요청 식별자 (예: 'mission_apply_123')
  /// [action]: 실행할 비동기 작업
  Future<T?> preventDuplicateSubmission<T>({
    required String requestId,
    required Future<T> Function() action,
    VoidCallback? onDuplicate,
  }) async {
    if (_pendingRequests.contains(requestId)) {
      onDuplicate?.call();
      return null;
    }

    _pendingRequests.add(requestId);
    try {
      return await action();
    } finally {
      _pendingRequests.remove(requestId);
    }
  }

  /// 디바운스 - 연속 호출 시 마지막 호출만 실행
  void debounce({
    required String key,
    required VoidCallback action,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(duration, () {
      action();
      _debounceTimers.remove(key);
    });
  }

  /// 스로틀 - 일정 시간 동안 한 번만 실행
  bool throttle({
    required String key,
    Duration duration = const Duration(seconds: 1),
  }) {
    final lastCall = _throttleTimestamps[key];
    final now = DateTime.now();

    if (lastCall == null || now.difference(lastCall) > duration) {
      _throttleTimestamps[key] = now;
      return true;
    }

    return false;
  }

  /// 재시도 로직 래퍼
  Future<T> withRetry<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await action();
      } on Exception catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  /// 타임아웃 래퍼
  Future<T> withTimeout<T>({
    required Future<T> Function() action,
    Duration timeout = const Duration(seconds: 30),
    T? defaultValue,
  }) async {
    try {
      return await action().timeout(timeout);
    } on TimeoutException {
      if (defaultValue != null) {
        return defaultValue;
      }
      throw TimeoutException('요청 시간이 초과되었습니다.');
    }
  }

  /// 정리
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingRequests.clear();
    _throttleTimestamps.clear();
  }
}

/// API 에러 타입
enum ApiErrorType {
  network,
  server,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  timeout,
  unknown,
}

/// API 에러 클래스
class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final String? code;
  final dynamic data;
  final List<String>? guidance;
  final String? action;

  ApiError({
    required this.type,
    required this.message,
    this.code,
    this.data,
    this.guidance,
    this.action,
  });

  factory ApiError.fromStatusCode(int statusCode, {String? message, dynamic data}) {
    ApiErrorType type;
    String defaultMessage;

    switch (statusCode) {
      case 400:
        type = ApiErrorType.validation;
        defaultMessage = '잘못된 요청입니다.';
        break;
      case 401:
        type = ApiErrorType.unauthorized;
        defaultMessage = '로그인이 필요합니다.';
        break;
      case 403:
        type = ApiErrorType.forbidden;
        defaultMessage = '권한이 없습니다.';
        break;
      case 404:
        type = ApiErrorType.notFound;
        defaultMessage = '요청한 리소스를 찾을 수 없습니다.';
        break;
      case 409:
        type = ApiErrorType.conflict;
        defaultMessage = '이미 처리된 요청입니다.';
        break;
      case 408:
      case 504:
        type = ApiErrorType.timeout;
        defaultMessage = '요청 시간이 초과되었습니다.';
        break;
      case 500:
      case 502:
      case 503:
        type = ApiErrorType.server;
        defaultMessage = '서버 오류가 발생했습니다.';
        break;
      default:
        type = ApiErrorType.unknown;
        defaultMessage = '오류가 발생했습니다.';
    }

    return ApiError(
      type: type,
      message: message ?? defaultMessage,
      data: data,
    );
  }

  factory ApiError.network({String? message}) {
    return ApiError(
      type: ApiErrorType.network,
      message: message ?? '네트워크 연결을 확인해주세요.',
      guidance: [
        '인터넷 연결 상태를 확인해주세요.',
        'Wi-Fi 또는 모바일 데이터가 켜져 있는지 확인해주세요.',
        '잠시 후 다시 시도해주세요.',
      ],
      action: 'retry',
    );
  }

  factory ApiError.timeout({String? message}) {
    return ApiError(
      type: ApiErrorType.timeout,
      message: message ?? '요청 시간이 초과되었습니다.',
      guidance: [
        '네트워크 상태가 불안정합니다.',
        '잠시 후 다시 시도해주세요.',
      ],
      action: 'retry',
    );
  }

  factory ApiError.unauthorized({String? message}) {
    return ApiError(
      type: ApiErrorType.unauthorized,
      message: message ?? '로그인이 필요합니다.',
      guidance: [
        '세션이 만료되었습니다.',
        '다시 로그인해주세요.',
      ],
      action: 'login',
    );
  }

  @override
  String toString() => 'ApiError[$type]: $message';
}

/// 에러 다이얼로그 표시 유틸리티
class ErrorDialogHelper {
  static void showErrorDialog(
    BuildContext context,
    ApiError error, {
    VoidCallback? onRetry,
    VoidCallback? onLogin,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          _getErrorIcon(error.type),
          size: 48,
          color: _getErrorColor(error.type),
        ),
        title: Text(
          _getErrorTitle(error.type),
          style: HwahaeTypography.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            if (error.guidance != null && error.guidance!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...error.guidance!.map((hint) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        hint,
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: _buildActions(context, error, onRetry, onLogin, onDismiss),
      ),
    );
  }

  static List<Widget> _buildActions(
    BuildContext context,
    ApiError error,
    VoidCallback? onRetry,
    VoidCallback? onLogin,
    VoidCallback? onDismiss,
  ) {
    final actions = <Widget>[];

    actions.add(
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          onDismiss?.call();
        },
        child: Text(
          '확인',
          style: HwahaeTypography.labelLarge.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ),
    );

    if (error.action == 'retry' && onRetry != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onRetry();
          },
          child: Text(
            '다시 시도',
            style: HwahaeTypography.labelLarge.copyWith(
              color: HwahaeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (error.action == 'login' && onLogin != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onLogin();
          },
          child: Text(
            '로그인',
            style: HwahaeTypography.labelLarge.copyWith(
              color: HwahaeColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return actions;
  }

  static IconData _getErrorIcon(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.network:
        return Icons.wifi_off_rounded;
      case ApiErrorType.server:
        return Icons.cloud_off_rounded;
      case ApiErrorType.unauthorized:
        return Icons.lock_outline_rounded;
      case ApiErrorType.forbidden:
        return Icons.block_rounded;
      case ApiErrorType.notFound:
        return Icons.search_off_rounded;
      case ApiErrorType.validation:
        return Icons.warning_amber_rounded;
      case ApiErrorType.conflict:
        return Icons.sync_problem_rounded;
      case ApiErrorType.timeout:
        return Icons.timer_off_rounded;
      case ApiErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  static Color _getErrorColor(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.network:
      case ApiErrorType.timeout:
        return HwahaeColors.warning;
      case ApiErrorType.server:
      case ApiErrorType.validation:
        return HwahaeColors.error;
      case ApiErrorType.unauthorized:
      case ApiErrorType.forbidden:
        return HwahaeColors.accent;
      case ApiErrorType.notFound:
        return HwahaeColors.info;
      case ApiErrorType.conflict:
        return HwahaeColors.warning;
      case ApiErrorType.unknown:
        return HwahaeColors.textSecondary;
    }
  }

  static String _getErrorTitle(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.network:
        return '네트워크 오류';
      case ApiErrorType.server:
        return '서버 오류';
      case ApiErrorType.unauthorized:
        return '로그인 필요';
      case ApiErrorType.forbidden:
        return '접근 권한 없음';
      case ApiErrorType.notFound:
        return '찾을 수 없음';
      case ApiErrorType.validation:
        return '입력 오류';
      case ApiErrorType.conflict:
        return '중복 요청';
      case ApiErrorType.timeout:
        return '요청 시간 초과';
      case ApiErrorType.unknown:
        return '오류 발생';
    }
  }
}

/// 스낵바 헬퍼
class SnackBarHelper {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HwahaeColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HwahaeColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HwahaeColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HwahaeColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 네트워크 오류용 스낵바 (재시도 버튼 포함)
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('네트워크 연결을 확인해주세요')),
          ],
        ),
        backgroundColor: HwahaeColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 5),
        action: onRetry != null
            ? SnackBarAction(
                label: '재시도',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// 중복 요청 경고 스낵바
  static void showDuplicateWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync_problem, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('요청을 처리 중입니다. 잠시만 기다려주세요.')),
          ],
        ),
        backgroundColor: HwahaeColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 로딩 오버레이 헬퍼
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {String? message}) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: HwahaeColors.primary,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: HwahaeTypography.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// 네트워크 모니터링 위젯
class NetworkStatusBanner extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onTap;

  const NetworkStatusBanner({
    super.key,
    required this.isConnected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: HwahaeColors.error,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              '네트워크 연결이 끊어졌습니다',
              style: HwahaeTypography.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
