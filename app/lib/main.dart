import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/config/environment.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 설정 초기화
  _initializeEnvironment();

  // 상태바 스타일 설정 (웹이 아닌 경우에만)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(const ProviderScope(child: AmhangeoheungApp()));
}

void _initializeEnvironment() {
  // 컴파일 타임 환경 변수로 환경 설정
  const envString = String.fromEnvironment('ENV', defaultValue: 'development');

  switch (envString) {
    case 'production':
      EnvironmentConfig.setEnvironment(Environment.production);
      break;
    case 'staging':
      EnvironmentConfig.setEnvironment(Environment.staging);
      break;
    default:
      EnvironmentConfig.setEnvironment(Environment.development);
  }

  if (EnvironmentConfig.enableLogging) {
    debugPrint('🚀 Environment: ${EnvironmentConfig.current.name}');
    debugPrint('🌐 API URL: ${EnvironmentConfig.apiBaseUrl}');
  }
}

class AmhangeoheungApp extends StatefulWidget {
  const AmhangeoheungApp({super.key});

  @override
  State<AmhangeoheungApp> createState() => _AmhangeoheungAppState();
}

class _AmhangeoheungAppState extends State<AmhangeoheungApp> {
  late StreamSubscription<void> _authExpiredSubscription;

  @override
  void initState() {
    super.initState();
    // 인증 만료 이벤트 구독
    _authExpiredSubscription = ApiClient().onAuthExpired.listen((_) {
      // 로그인 화면으로 리다이렉트
      AppRouter.router.go('/login');

      // 사용자에게 알림 표시
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('세션이 만료되었습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authExpiredSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '암행어흥',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
