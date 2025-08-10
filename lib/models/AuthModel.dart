class AuthModel {
  final String accessToken;
  final String tokenType;

  AuthModel({required this.accessToken, required this.tokenType});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {'access_token': accessToken, 'token_type': tokenType};
  }

  @override
  String toString() {
    return 'AuthModel(accessToken: $accessToken, tokenType: $tokenType)';
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final AuthModel? data;

  AuthResponse({required this.success, required this.message, this.data});

  factory AuthResponse.success(AuthModel data) {
    return AuthResponse(success: true, message: 'Success', data: data);
  }

  factory AuthResponse.error(String message) {
    return AuthResponse(success: false, message: message);
  }
}
