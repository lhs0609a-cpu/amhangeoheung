import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// 소셜 로그인 프로바이더 타입
enum SocialProvider {
  google,
  apple,
  kakao,
}

/// 소셜 로그인 결과 모델
class SocialAuthResult {
  final bool success;
  final String? errorMessage;
  final SocialUserInfo? userInfo;

  SocialAuthResult({
    required this.success,
    this.errorMessage,
    this.userInfo,
  });

  factory SocialAuthResult.success(SocialUserInfo userInfo) {
    return SocialAuthResult(success: true, userInfo: userInfo);
  }

  factory SocialAuthResult.failure(String message) {
    return SocialAuthResult(success: false, errorMessage: message);
  }
}

/// 소셜 로그인으로 받아온 사용자 정보
class SocialUserInfo {
  final SocialProvider provider;
  final String providerId;
  final String? email;
  final String? name;
  final String? profileImage;
  final String? idToken;
  final String? accessToken;

  SocialUserInfo({
    required this.provider,
    required this.providerId,
    this.email,
    this.name,
    this.profileImage,
    this.idToken,
    this.accessToken,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'providerId': providerId,
        'email': email,
        'name': name,
        'profileImage': profileImage,
        'idToken': idToken,
        'accessToken': accessToken,
      };
}

/// 소셜 로그인 서비스
class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  // Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Kakao SDK 초기화 (앱 시작 시 호출)
  static void initializeKakao() {
    const kakaoAppKey = String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY',
      defaultValue: 'YOUR_KAKAO_NATIVE_APP_KEY',
    );
    KakaoSdk.init(nativeAppKey: kakaoAppKey);
  }

  /// Google 로그인
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      // 기존 로그인 세션 클리어
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return SocialAuthResult.failure('Google 로그인이 취소되었습니다.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      return SocialAuthResult.success(
        SocialUserInfo(
          provider: SocialProvider.google,
          providerId: googleUser.id,
          email: googleUser.email,
          name: googleUser.displayName,
          profileImage: googleUser.photoUrl,
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ),
      );
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return SocialAuthResult.failure('Google 로그인 중 오류가 발생했습니다.');
    }
  }

  /// Apple 로그인
  Future<SocialAuthResult> signInWithApple() async {
    try {
      // nonce 생성 (보안을 위해)
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Apple은 첫 로그인 시에만 이름을 제공
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName =
            '${credential.familyName ?? ''}${credential.givenName ?? ''}'.trim();
        if (fullName.isEmpty) fullName = null;
      }

      return SocialAuthResult.success(
        SocialUserInfo(
          provider: SocialProvider.apple,
          providerId: credential.userIdentifier ?? '',
          email: credential.email,
          name: fullName,
          profileImage: null, // Apple doesn't provide profile image
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return SocialAuthResult.failure('Apple 로그인이 취소되었습니다.');
      }
      debugPrint('Apple sign in error: ${e.message}');
      return SocialAuthResult.failure('Apple 로그인 중 오류가 발생했습니다.');
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return SocialAuthResult.failure('Apple 로그인 중 오류가 발생했습니다.');
    }
  }

  /// 카카오 로그인
  Future<SocialAuthResult> signInWithKakao() async {
    try {
      OAuthToken token;

      // 카카오톡 앱이 설치되어 있으면 카카오톡으로 로그인
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          debugPrint('Kakao Talk login failed, trying Kakao Account: $e');
          // 카카오톡 로그인 실패 시 카카오 계정으로 로그인
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 카카오톡 앱이 없으면 카카오 계정으로 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 사용자 정보 가져오기
      User user = await UserApi.instance.me();

      return SocialAuthResult.success(
        SocialUserInfo(
          provider: SocialProvider.kakao,
          providerId: user.id.toString(),
          email: user.kakaoAccount?.email,
          name: user.kakaoAccount?.profile?.nickname,
          profileImage: user.kakaoAccount?.profile?.profileImageUrl,
          accessToken: token.accessToken,
          idToken: token.idToken,
        ),
      );
    } catch (e) {
      debugPrint('Kakao sign in error: $e');
      if (e.toString().contains('CANCELED')) {
        return SocialAuthResult.failure('카카오 로그인이 취소되었습니다.');
      }
      return SocialAuthResult.failure('카카오 로그인 중 오류가 발생했습니다.');
    }
  }

  /// 소셜 로그인 (통합)
  Future<SocialAuthResult> signIn(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        return signInWithGoogle();
      case SocialProvider.apple:
        return signInWithApple();
      case SocialProvider.kakao:
        return signInWithKakao();
    }
  }

  /// 로그아웃 (소셜 세션 클리어)
  Future<void> signOut(SocialProvider provider) async {
    try {
      switch (provider) {
        case SocialProvider.google:
          await _googleSignIn.signOut();
          break;
        case SocialProvider.apple:
          // Apple doesn't have a sign out API
          break;
        case SocialProvider.kakao:
          await UserApi.instance.logout();
          break;
      }
    } catch (e) {
      debugPrint('Social sign out error: $e');
    }
  }

  /// 모든 소셜 로그인 세션 클리어
  Future<void> signOutAll() async {
    await Future.wait([
      signOut(SocialProvider.google),
      signOut(SocialProvider.kakao),
    ]);
  }

  /// nonce 생성 (Apple Sign In 보안용)
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 해시 생성
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
