import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// 백그라운드 메시지 핸들러 (top-level function 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  bool _initialized = false;

  String? get currentToken => _currentToken;

  /// FCM 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 백그라운드 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 알림 권한 요청
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permission denied');
        return;
      }

      debugPrint(
          '[FCM] Permission: ${settings.authorizationStatus}');

      // 토큰 획득
      _currentToken = await _messaging.getToken();
      debugPrint('[FCM] Token: $_currentToken');

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // 포그라운드 알림 설정
      await _setupForegroundHandler();

      // 알림 탭 핸들러
      _handleMessageOpened();

      _initialized = true;
      debugPrint('[FCM] Initialized successfully');
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// 토큰 갱신 시 백엔드 재등록
  void _onTokenRefresh(String newToken) {
    debugPrint('[FCM] Token refreshed: $newToken');
    _currentToken = newToken;
    registerTokenWithBackend(newToken);
  }

  /// 백엔드에 디바이스 토큰 등록
  Future<void> registerTokenWithBackend(String? token) async {
    token ??= _currentToken;
    if (token == null) return;

    try {
      String platform;
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else {
        platform = 'web';
      }

      await ApiClient().post('/notifications/device-token', data: {
        'token': token,
        'platform': platform,
      });
      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      debugPrint('[FCM] Failed to register token: $e');
    }
  }

  /// 백엔드에서 디바이스 토큰 제거
  Future<void> removeTokenFromBackend() async {
    if (_currentToken == null) return;

    try {
      await ApiClient().delete('/notifications/device-token', data: {
        'token': _currentToken,
      });
      debugPrint('[FCM] Token removed from backend');
    } catch (e) {
      debugPrint('[FCM] Failed to remove token: $e');
    }
  }

  /// 포그라운드 알림 핸들러 설정
  Future<void> _setupForegroundHandler() async {
    // Android 알림 채널
    const androidChannel = AndroidNotificationChannel(
      'amhangeoheung_notifications',
      '암행어흥 알림',
      description: '암행어흥 서비스 알림',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 로컬 알림 초기화
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notification tapped: ${response.payload}');
      },
    );

    // 포그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');

      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['type'],
      );
    });
  }

  /// 알림 탭 시 화면 이동 처리
  void _handleMessageOpened() {
    // 앱이 백그라운드에서 알림 탭으로 열릴 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened: ${message.data}');
      _navigateByType(message.data);
    });

    // 앱이 종료 상태에서 알림 탭으로 열릴 때
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM] Initial message: ${message.data}');
        _navigateByType(message.data);
      }
    });
  }

  /// 알림 타입에 따른 화면 라우팅
  void _navigateByType(Map<String, dynamic> data) {
    // 라우팅은 go_router의 context가 필요하므로
    // 추후 GoRouter 통합 시 구현
    debugPrint('[FCM] Navigate by type: ${data['type']}');
  }
}
