import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class TrustRepository {
  final ApiClient _apiClient = ApiClient();

  Future<TrustAnalysisResponse> getTrustAnalysis(String businessId) async {
    try {
      final response = await _apiClient.get('/businesses/$businessId/trust-analysis');

      if (response.data['success']) {
        return TrustAnalysisResponse(
          success: true,
          data: TrustAnalysisData.fromJson(response.data['data']),
        );
      }

      return TrustAnalysisResponse(
        success: false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return TrustAnalysisResponse(
        success: false,
        message: e.response?.data?['message'] ?? '서버 오류가 발생했습니다.',
      );
    }
  }
}

class TrustAnalysisResponse {
  final bool success;
  final String? message;
  final TrustAnalysisData? data;

  TrustAnalysisResponse({required this.success, this.message, this.data});
}

class TrustAnalysisData {
  final String businessName;
  final String category;
  final int trustScore;
  final String grade;
  final int totalReviews;
  final double averageScore;
  final String badgeLevel;
  final List<TrustTrend> trend;
  final CategoryComparison categoryComparison;

  TrustAnalysisData({
    required this.businessName,
    required this.category,
    required this.trustScore,
    required this.grade,
    required this.totalReviews,
    required this.averageScore,
    required this.badgeLevel,
    required this.trend,
    required this.categoryComparison,
  });

  factory TrustAnalysisData.fromJson(Map<String, dynamic> json) {
    return TrustAnalysisData(
      businessName: json['businessName'] ?? '',
      category: json['category'] ?? '',
      trustScore: json['trustScore'] ?? 0,
      grade: json['grade'] ?? 'D',
      totalReviews: json['totalReviews'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      badgeLevel: json['badgeLevel'] ?? 'none',
      trend: (json['trend'] as List?)
              ?.map((t) => TrustTrend.fromJson(t))
              .toList() ??
          [],
      categoryComparison: CategoryComparison.fromJson(
          json['categoryComparison'] ?? {}),
    );
  }
}

class TrustTrend {
  final String month;
  final double averageScore;
  final int reviewCount;

  TrustTrend({
    required this.month,
    required this.averageScore,
    required this.reviewCount,
  });

  factory TrustTrend.fromJson(Map<String, dynamic> json) {
    return TrustTrend(
      month: json['month'] ?? '',
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}

class CategoryComparison {
  final double categoryAverage;
  final double difference;
  final int totalInCategory;

  CategoryComparison({
    required this.categoryAverage,
    required this.difference,
    required this.totalInCategory,
  });

  factory CategoryComparison.fromJson(Map<String, dynamic> json) {
    return CategoryComparison(
      categoryAverage: (json['categoryAverage'] ?? 0).toDouble(),
      difference: (json['difference'] ?? 0).toDouble(),
      totalInCategory: json['totalInCategory'] ?? 0,
    );
  }
}
