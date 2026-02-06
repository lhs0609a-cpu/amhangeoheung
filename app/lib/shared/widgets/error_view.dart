import 'package:flutter/material.dart';
import '../../core/theme/hwahae_colors.dart';
import '../../core/theme/hwahae_typography.dart';

enum ErrorType {
  network,
  server,
  notFound,
  unknown,
}

class ErrorView extends StatelessWidget {
  final ErrorType errorType;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.errorType = ErrorType.unknown,
    this.errorMessage,
    this.onRetry,
  });

  factory ErrorView.fromMessage({
    required String message,
    VoidCallback? onRetry,
  }) {
    ErrorType type = ErrorType.unknown;
    if (message.contains('network') || message.contains('connection')) {
      type = ErrorType.network;
    } else if (message.contains('server') || message.contains('500')) {
      type = ErrorType.server;
    } else if (message.contains('not found') || message.contains('404')) {
      type = ErrorType.notFound;
    }

    return ErrorView(
      errorType: type,
      errorMessage: message,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 24),
            Text(
              _getTitle(),
              style: HwahaeTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? _getDefaultMessage(),
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HwahaeColors.primary,
                  foregroundColor: HwahaeColors.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (errorType) {
      case ErrorType.network:
        icon = Icons.wifi_off;
        color = HwahaeColors.warning;
        break;
      case ErrorType.server:
        icon = Icons.cloud_off;
        color = HwahaeColors.error;
        break;
      case ErrorType.notFound:
        icon = Icons.search_off;
        color = HwahaeColors.info;
        break;
      case ErrorType.unknown:
        icon = Icons.error_outline;
        color = HwahaeColors.textSecondary;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  String _getTitle() {
    switch (errorType) {
      case ErrorType.network:
        return '네트워크 연결 오류';
      case ErrorType.server:
        return '서버 오류';
      case ErrorType.notFound:
        return '찾을 수 없습니다';
      case ErrorType.unknown:
        return '오류가 발생했습니다';
    }
  }

  String _getDefaultMessage() {
    switch (errorType) {
      case ErrorType.network:
        return '인터넷 연결을 확인해주세요';
      case ErrorType.server:
        return '잠시 후 다시 시도해주세요';
      case ErrorType.notFound:
        return '요청하신 내용을 찾을 수 없습니다';
      case ErrorType.unknown:
        return '문제가 발생했습니다. 다시 시도해주세요';
    }
  }
}
