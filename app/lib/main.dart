import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/config/environment.dart';
import 'core/config/company_info.dart';
import 'core/services/fcm_service.dart';
import 'app_router.dart';
import 'shared/widgets/app_scroll_behavior.dart';
import 'shared/widgets/ui/app_toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 설정 초기화
  _initializeEnvironment();

  // 운영 빌드에 필수 사업자 법적 정보가 주입되지 않았으면 부팅을 중단한다.
  // (전자상거래법상 필수 표기 누락 상태로 출시되는 것을 방지)
  CompanyInfo.assertReleaseReady();
  CompanyInfo.warnIfUnfilled();

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    await FcmService().initialize();
  } catch (e) {
    debugPrint('[FIREBASE] Initialization failed: $e');
  }

  // 시스템 UI: 콘텐츠를 상/하단 시스템 바 뒤까지 확장하고(edge-to-edge),
  // 바 자체는 투명하게 둔다. 안드로이드 3버튼 네비게이션 바에 생기는
  // 회색 띠를 없애 화면을 끝까지 쓰기 위한 설정이다.
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 모바일은 세로 고정. 가로 회전 시 레이아웃이 무너지는 화면이 많고,
    // 가로 지원은 별도 디자인이 필요하다.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const ProviderScope(child: AmhangeoheungApp()));
}

void _initializeEnvironment() {
  // 컴파일 타임 환경 변수로 환경 설정.
  // ENV 미지정 시: release 빌드는 production(https), 그 외는 development.
  // → 실수로 release가 localhost를 가리키는 사고를 방지한다.
  const envFlag = String.fromEnvironment('ENV', defaultValue: '');
  final envString = envFlag.isNotEmpty
      ? envFlag
      : (kReleaseMode ? 'production' : 'development');

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
      if (context != null && context.mounted) {
        AppToast.warning(context, '세션이 만료되었습니다. 다시 로그인해주세요.');
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
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        // OS 글자 크기 설정을 존중하되 상한을 둔다. 130% 를 넘어가면
        // 카드/버튼 안의 2줄 레이아웃이 깨지는 화면이 나온다.
        final scaler = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
