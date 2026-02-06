class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<ApiError>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] != null
          ? (json['errors'] as List)
              .map((e) => ApiError.fromJson(e))
              .toList()
          : null,
    );
  }
}

class ApiError {
  final String? field;
  final String message;

  ApiError({this.field, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      field: json['field'] ?? json['param'],
      message: json['message'] ?? json['msg'] ?? 'Unknown error',
    );
  }
}
