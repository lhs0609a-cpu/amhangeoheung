import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// 알림 수신 설정.
///
/// 필드 이름은 백엔드 컬럼과 그대로 맞춘다. 화면 문구와 컬럼 사이에 이름을
/// 한 번 더 번역하면, 스위치 하나를 늘릴 때 고칠 곳이 세 군데가 된다.
class NotificationSettings {
  const NotificationSettings({
    this.push = true,
    this.mission = true,
    this.review = true,
    this.settlement = true,
    this.marketing = false,
    this.night = false,
  });

  /// 마스터 스위치. 끄면 푸시가 오지 않는다 (앱 안 알림 목록에는 쌓인다).
  final bool push;

  final bool mission;
  final bool review;
  final bool settlement;

  /// 광고성 정보. 기본값이 꺼짐인 것은 취향이 아니라 정보통신망법이다.
  final bool marketing;

  /// 야간(21:00~08:00) 푸시 허용
  final bool night;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    bool read(String key, bool fallback) => json[key] as bool? ?? fallback;
    return NotificationSettings(
      push: read('notification_push', true),
      mission: read('notify_mission', true),
      review: read('notify_review', true),
      settlement: read('notify_settlement', true),
      marketing: read('notify_marketing', false),
      night: read('notify_night', false),
    );
  }

  Map<String, dynamic> toJson() => {
        'notification_push': push,
        'notify_mission': mission,
        'notify_review': review,
        'notify_settlement': settlement,
        'notify_marketing': marketing,
        'notify_night': night,
      };

  NotificationSettings copyWith({
    bool? push,
    bool? mission,
    bool? review,
    bool? settlement,
    bool? marketing,
    bool? night,
  }) {
    return NotificationSettings(
      push: push ?? this.push,
      mission: mission ?? this.mission,
      review: review ?? this.review,
      settlement: settlement ?? this.settlement,
      marketing: marketing ?? this.marketing,
      night: night ?? this.night,
    );
  }
}

class NotificationSettingsState {
  const NotificationSettingsState({
    this.settings = const NotificationSettings(),
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  final NotificationSettings settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  NotificationSettingsState copyWith({
    NotificationSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(const NotificationSettingsState()) {
    load();
  }

  final ApiClient _api = ApiClient();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get('/users/me/notifications');
      final data = response.data['data']?['settings'] as Map<String, dynamic>?;
      state = state.copyWith(
        settings: data == null
            ? const NotificationSettings()
            : NotificationSettings.fromJson(data),
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.extractErrorMessage(e) ?? '알림 설정을 불러오지 못했습니다',
      );
    }
  }

  /// 스위치 하나를 바꾼다.
  ///
  /// 화면을 먼저 바꾸고 서버에 보낸다. 실패하면 되돌린다 — 스위치가 서버
  /// 응답을 기다리며 굳어 있으면 연달아 몇 개를 끄기가 답답하다. 다만
  /// **되돌리는 것까지 해야** 저장된 줄 알고 나가는 일이 없다.
  Future<bool> update(NotificationSettings next) async {
    final previous = state.settings;
    state = state.copyWith(settings: next, isSaving: true, clearError: true);

    try {
      final response = await _api.put(
        '/users/me/notifications',
        data: next.toJson(),
      );
      final data = response.data['data']?['settings'] as Map<String, dynamic>?;
      state = state.copyWith(
        // 서버가 돌려준 값을 정답으로 삼는다. 마케팅 동의처럼 서버가
        // 부수적으로 손대는 값이 있을 수 있다.
        settings:
            data == null ? next : NotificationSettings.fromJson(data),
        isSaving: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        settings: previous,
        isSaving: false,
        error: ApiClient.extractErrorMessage(e) ?? '알림 설정을 저장하지 못했습니다',
      );
      return false;
    }
  }
}

final notificationSettingsProvider = StateNotifierProvider.autoDispose<
    NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(),
);
