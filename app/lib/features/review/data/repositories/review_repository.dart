import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final ApiClient _apiClient = ApiClient();

  // 공개된 리뷰 목록 조회
  Future<ReviewListResponse> getReviews({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/reviews',
        queryParameters: {
          if (category != null) 'category': category,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        final reviews = (response.data['data']['reviews'] as List)
            .map((r) => ReviewModel.fromJson(r))
            .toList();
        return ReviewListResponse(success: true, reviews: reviews);
      }

      return ReviewListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 트렌딩 리뷰 조회
  Future<ReviewListResponse> getTrendingReviews() async {
    try {
      final response = await _apiClient.get('/reviews/trending');

      if (response.data['success']) {
        final reviews = (response.data['data']['reviews'] as List)
            .map((r) => ReviewModel.fromJson(r))
            .toList();
        return ReviewListResponse(success: true, reviews: reviews);
      }

      return ReviewListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 최근 리뷰 조회
  Future<ReviewListResponse> getRecentReviews() async {
    try {
      final response = await _apiClient.get('/reviews/recent');

      if (response.data['success']) {
        final reviews = (response.data['data']['reviews'] as List)
            .map((r) => ReviewModel.fromJson(r))
            .toList();
        return ReviewListResponse(success: true, reviews: reviews);
      }

      return ReviewListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 리뷰 상세 조회
  Future<ReviewDetailResponse> getReviewDetail(String reviewId) async {
    try {
      final response = await _apiClient.get('/reviews/$reviewId');

      if (response.data['success']) {
        return ReviewDetailResponse(
          success: true,
          review: ReviewModel.fromJson(response.data['data']['review']),
        );
      }

      return ReviewDetailResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewDetailResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 내 리뷰 목록 조회
  Future<ReviewListResponse> getMyReviews() async {
    try {
      final response = await _apiClient.get('/reviews/my');

      if (response.data['success']) {
        final reviews = (response.data['data']['reviews'] as List)
            .map((r) => ReviewModel.fromJson(r))
            .toList();
        return ReviewListResponse(success: true, reviews: reviews);
      }

      return ReviewListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 리뷰 작성
  Future<ReviewCreateResponse> createReview({
    required String missionId,
    required Map<String, int> scores,
    required List<String> pros,
    required List<String> cons,
    String? summary,
  }) async {
    try {
      final response = await _apiClient.post('/reviews', data: {
        'missionId': missionId,
        'scores': scores,
        'content': {
          'pros': pros,
          'cons': cons,
          'summary': summary,
        },
      });

      if (response.data['success']) {
        return ReviewCreateResponse(
          success: true,
          message: response.data['message'],
          review: ReviewModel.fromJson(response.data['data']['review']),
        );
      }

      return ReviewCreateResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewCreateResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 리뷰 임시저장 (초안 업데이트)
  Future<ReviewCreateResponse> saveDraft({
    required String missionId,
    String? reviewId,
    Map<String, int>? scores,
    List<String>? pros,
    List<String>? cons,
    String? summary,
    String? detailedReview,
  }) async {
    try {
      // 기존 리뷰가 있으면 업데이트, 없으면 새로 생성
      if (reviewId != null) {
        final response = await _apiClient.put('/reviews/$reviewId', data: {
          if (scores != null) 'scores': scores,
          'content': {
            if (pros != null) 'pros': pros,
            if (cons != null) 'cons': cons,
            if (summary != null) 'summary': summary,
            if (detailedReview != null) 'detailedReview': detailedReview,
          },
        });

        if (response.data['success']) {
          return ReviewCreateResponse(
            success: true,
            message: '임시 저장되었습니다.',
            review: ReviewModel.fromJson(response.data['data']['review']),
          );
        }

        return ReviewCreateResponse(
          success: false,
          message: response.data['message'],
        );
      } else {
        // 새 리뷰 초안 생성
        return createReview(
          missionId: missionId,
          scores: scores ?? {},
          pros: pros ?? [],
          cons: cons ?? [],
          summary: summary,
        );
      }
    } on DioException catch (e) {
      return ReviewCreateResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 리뷰 제출
  Future<ApiResponse> submitReview(String reviewId) async {
    try {
      final response = await _apiClient.post('/reviews/$reviewId/submit');

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 사진 업로드
  Future<ApiResponse> uploadPhotos({
    required String reviewId,
    required List<Map<String, String>> photos,
  }) async {
    try {
      final response = await _apiClient.post('/reviews/$reviewId/photos', data: {
        'photos': photos,
      });

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 영수증 업로드
  Future<ApiResponse> uploadReceipt({
    required String reviewId,
    required String imageUrl,
    Map<String, dynamic>? ocrData,
  }) async {
    try {
      final response = await _apiClient.post('/reviews/$reviewId/receipt', data: {
        'imageUrl': imageUrl,
        'ocrData': ocrData,
      });

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 유용성 투표
  Future<ApiResponse> markHelpful(String reviewId) async {
    try {
      final response = await _apiClient.post('/reviews/$reviewId/helpful');

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 리뷰 신고
  Future<ApiResponse> reportReview(String reviewId, {String? reason}) async {
    try {
      final response = await _apiClient.post('/reviews/$reviewId/report', data: {
        if (reason != null) 'reason': reason,
      });

      return ApiResponse(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // 리뷰 검색
  Future<ReviewListResponse> searchReviews(String query) async {
    try {
      final response = await _apiClient.get(
        '/reviews',
        queryParameters: {
          'search': query,
          'limit': 20,
        },
      );

      if (response.data['success']) {
        final reviews = (response.data['data']['reviews'] as List)
            .map((r) => ReviewModel.fromJson(r))
            .toList();
        return ReviewListResponse(success: true, reviews: reviews);
      }

      return ReviewListResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ReviewListResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response != null) {
      return e.response!.data['message'] ?? '오류가 발생했습니다.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 연결 시간이 초과되었습니다.';
      case DioExceptionType.connectionError:
        return '네트워크 연결을 확인해주세요.';
      default:
        return '서버 오류가 발생했습니다.';
    }
  }
}

// Response Classes
class ApiResponse {
  final bool success;
  final String? message;

  ApiResponse({required this.success, this.message});
}

class ReviewListResponse {
  final bool success;
  final String? message;
  final List<ReviewModel> reviews;

  ReviewListResponse({
    required this.success,
    this.message,
    this.reviews = const [],
  });
}

class ReviewDetailResponse {
  final bool success;
  final String? message;
  final ReviewModel? review;

  ReviewDetailResponse({
    required this.success,
    this.message,
    this.review,
  });
}

class ReviewCreateResponse {
  final bool success;
  final String? message;
  final ReviewModel? review;

  ReviewCreateResponse({
    required this.success,
    this.message,
    this.review,
  });
}
