import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationVerificationProvider =
    StateNotifierProvider<LocationVerificationNotifier, LocationVerificationState>(
        (ref) => LocationVerificationNotifier());

class LocationVerificationState {
  final bool isVerifying;
  final bool isVerified;
  final bool isMockDetected;
  final Position? position;
  final String? errorMessage;

  LocationVerificationState({
    this.isVerifying = false,
    this.isVerified = false,
    this.isMockDetected = false,
    this.position,
    this.errorMessage,
  });

  LocationVerificationState copyWith({
    bool? isVerifying,
    bool? isVerified,
    bool? isMockDetected,
    Position? position,
    String? errorMessage,
  }) {
    return LocationVerificationState(
      isVerifying: isVerifying ?? this.isVerifying,
      isVerified: isVerified ?? this.isVerified,
      isMockDetected: isMockDetected ?? this.isMockDetected,
      position: position ?? this.position,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocationVerificationNotifier extends StateNotifier<LocationVerificationState> {
  LocationVerificationNotifier() : super(LocationVerificationState());

  Future<void> verifyLocationWithSampling() async {
    state = state.copyWith(isVerifying: true, errorMessage: null);

    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isVerifying: false,
            errorMessage: '위치 권한이 필요합니다',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isVerifying: false,
          errorMessage: '설정에서 위치 권한을 허용해주세요',
        );
        return;
      }

      // 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Mock location 탐지 (Android)
      if (position.isMocked) {
        state = state.copyWith(
          isVerifying: false,
          isMockDetected: true,
        );
        return;
      }

      state = state.copyWith(
        isVerifying: false,
        isVerified: true,
        position: position,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: '위치를 가져올 수 없습니다: ${e.toString()}',
      );
    }
  }

  bool isWithinRadius(double targetLat, double targetLng, double radiusMeters) {
    if (state.position == null) return false;

    final distance = Geolocator.distanceBetween(
      state.position!.latitude,
      state.position!.longitude,
      targetLat,
      targetLng,
    );

    return distance <= radiusMeters;
  }

  void reset() {
    state = LocationVerificationState();
  }
}
