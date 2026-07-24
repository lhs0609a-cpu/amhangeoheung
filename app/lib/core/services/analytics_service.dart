import 'dart:async';
import 'dart:collection';
import '../network/api_client.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final ApiClient _apiClient = ApiClient();
  final Queue<Map<String, dynamic>> _eventQueue = Queue();
  Timer? _flushTimer;
  String? _sessionId;
  String? _deviceId;

  void initialize({String? sessionId, String? deviceId}) {
    _sessionId = sessionId;
    _deviceId = deviceId;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  void trackEvent(String name, String category, {Map<String, dynamic>? data}) {
    _eventQueue.add({
      'eventName': name,
      'eventCategory': category,
      'eventData': data ?? {},
      'sessionId': _sessionId,
      'deviceId': _deviceId,
      'platform': 'mobile',
    });

    if (_eventQueue.length >= 20) flush();
  }

  void trackScreenView(String screenName) {
    trackEvent('screen_view', 'navigation', data: {'screen': screenName});
  }

  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    final events = _eventQueue.toList();
    _eventQueue.clear();

    try {
      await _apiClient.post('/analytics/batch', data: {'events': events});
    } catch (_) {
      // Re-queue on failure
      for (final event in events) {
        _eventQueue.add(event);
      }
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}
