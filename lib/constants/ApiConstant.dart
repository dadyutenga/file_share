class ApiConstants {
  // Base URL - Update this to your backend URL
  static const String baseUrl = 'https://myfiles.dadyprojects.systems';

  // Authentication endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';

  // Headers for form data
  static const Map<String, String> formHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  // Headers for JSON data
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // Headers with auth token
  static Map<String, String> authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
