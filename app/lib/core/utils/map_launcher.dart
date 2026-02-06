import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 외부 지도 앱을 실행하는 유틸리티 클래스
class MapLauncher {
  MapLauncher._();

  /// 지도 앱 목록 (우선순위 순)
  static const List<MapApp> _mapApps = [
    MapApp.kakaoMap,
    MapApp.naverMap,
    MapApp.googleMaps,
  ];

  /// 좌표로 지도 앱 열기
  ///
  /// [latitude] 위도
  /// [longitude] 경도
  /// [name] 장소 이름 (선택)
  /// [address] 주소 (선택)
  static Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    // 설치된 지도 앱 찾기
    for (final mapApp in _mapApps) {
      final uri = _buildUri(
        mapApp: mapApp,
        latitude: latitude,
        longitude: longitude,
        name: name,
        address: address,
      );

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    // 설치된 앱이 없으면 웹 브라우저로 구글맵 열기
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    return await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// 특정 지도 앱으로 열기
  static Future<bool> openWithApp({
    required MapApp mapApp,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    final uri = _buildUri(
      mapApp: mapApp,
      latitude: latitude,
      longitude: longitude,
      name: name,
      address: address,
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // 앱이 없으면 스토어로 이동
    return await _openStore(mapApp);
  }

  /// 지도 앱 선택 다이얼로그 표시
  static Future<void> showMapAppPicker({
    required BuildContext context,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    final availableApps = await _getAvailableApps();

    if (!context.mounted) return;

    if (availableApps.isEmpty) {
      // 설치된 앱이 없으면 바로 웹으로 열기
      await openMap(
        latitude: latitude,
        longitude: longitude,
        name: name,
        address: address,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapAppPickerSheet(
        availableApps: availableApps,
        latitude: latitude,
        longitude: longitude,
        name: name,
        address: address,
      ),
    );
  }

  /// 설치된 지도 앱 목록 조회
  static Future<List<MapApp>> _getAvailableApps() async {
    final available = <MapApp>[];

    for (final app in _mapApps) {
      final uri = _buildUri(
        mapApp: app,
        latitude: 37.5665,
        longitude: 126.9780,
      );

      if (await canLaunchUrl(uri)) {
        available.add(app);
      }
    }

    return available;
  }

  /// 지도 앱별 URI 생성
  static Uri _buildUri({
    required MapApp mapApp,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) {
    switch (mapApp) {
      case MapApp.kakaoMap:
        // 카카오맵 URL Scheme
        // kakaomap://look?p=37.5665,126.9780
        return Uri.parse(
          'kakaomap://look?p=$latitude,$longitude',
        );

      case MapApp.naverMap:
        // 네이버맵 URL Scheme
        // nmap://place?lat=37.5665&lng=126.9780&name=장소명&appname=com.example.app
        final encodedName = Uri.encodeComponent(name ?? '목적지');
        return Uri.parse(
          'nmap://place?lat=$latitude&lng=$longitude&name=$encodedName&appname=com.amhangeoheung.app',
        );

      case MapApp.googleMaps:
        // 구글맵 URL Scheme
        if (Platform.isIOS) {
          return Uri.parse(
            'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=transit',
          );
        } else {
          return Uri.parse(
            'google.navigation:q=$latitude,$longitude',
          );
        }
    }
  }

  /// 앱스토어/플레이스토어 열기
  static Future<bool> _openStore(MapApp mapApp) async {
    final String storeUrl;

    if (Platform.isIOS) {
      switch (mapApp) {
        case MapApp.kakaoMap:
          storeUrl = 'https://apps.apple.com/app/id304608425';
          break;
        case MapApp.naverMap:
          storeUrl = 'https://apps.apple.com/app/id311867728';
          break;
        case MapApp.googleMaps:
          storeUrl = 'https://apps.apple.com/app/id585027354';
          break;
      }
    } else {
      switch (mapApp) {
        case MapApp.kakaoMap:
          storeUrl = 'market://details?id=net.daum.android.map';
          break;
        case MapApp.naverMap:
          storeUrl = 'market://details?id=com.nhn.android.nmap';
          break;
        case MapApp.googleMaps:
          storeUrl = 'market://details?id=com.google.android.apps.maps';
          break;
      }
    }

    final uri = Uri.parse(storeUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// 지원하는 지도 앱
enum MapApp {
  kakaoMap,
  naverMap,
  googleMaps,
}

extension MapAppExtension on MapApp {
  String get displayName {
    switch (this) {
      case MapApp.kakaoMap:
        return '카카오맵';
      case MapApp.naverMap:
        return '네이버 지도';
      case MapApp.googleMaps:
        return 'Google Maps';
    }
  }

  IconData get icon {
    switch (this) {
      case MapApp.kakaoMap:
        return Icons.map;
      case MapApp.naverMap:
        return Icons.explore;
      case MapApp.googleMaps:
        return Icons.public;
    }
  }

  Color get color {
    switch (this) {
      case MapApp.kakaoMap:
        return const Color(0xFFFFE812);
      case MapApp.naverMap:
        return const Color(0xFF03C75A);
      case MapApp.googleMaps:
        return const Color(0xFF4285F4);
    }
  }
}

/// 지도 앱 선택 바텀시트
class _MapAppPickerSheet extends StatelessWidget {
  final List<MapApp> availableApps;
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  const _MapAppPickerSheet({
    required this.availableApps,
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 핸들바
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // 제목
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '지도 앱 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (name != null || address != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name ?? address ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            // 앱 목록
            ...availableApps.map((app) => _buildAppTile(context, app)),
            const SizedBox(height: 8),
            // 웹으로 보기 옵션
            _buildWebOption(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTile(BuildContext context, MapApp app) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: app.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          app.icon,
          color: app.color,
        ),
      ),
      title: Text(
        app.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        Navigator.pop(context);
        await MapLauncher.openWithApp(
          mapApp: app,
          latitude: latitude,
          longitude: longitude,
          name: name,
          address: address,
        );
      },
    );
  }

  Widget _buildWebOption(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.language,
          color: Colors.grey[600],
        ),
      ),
      title: const Text(
        '웹 브라우저로 열기',
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        Navigator.pop(context);
        final webUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      },
    );
  }
}
