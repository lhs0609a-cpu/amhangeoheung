import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final UserModel? user;
  final List<dynamic>? errors;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.errors,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: data?['token'],
      user: data?['user'] != null ? UserModel.fromJson(data!['user']) : null,
      errors: json['errors'],
    );
  }

  String get errorMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.map((e) => e['msg'] ?? e.toString()).join(', ');
    }
    return message ?? '알 수 없는 오류가 발생했습니다.';
  }
}
