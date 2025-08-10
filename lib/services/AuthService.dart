import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/ApiConstant.dart';
import '../models/AuthModel.dart';

class AuthService {
  static final Dio _dio = Dio();

  // Initialize Dio with base configuration
  static void _initializeDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  // Register User
  static Future<AuthResponse> registerUser(
    String username,
    String password,
  ) async {
    try {
      _initializeDio();

      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: {'username': username, 'password': password},
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      if (response.statusCode == 200) {
        final authModel = AuthModel.fromJson(response.data);
        return AuthResponse.success(authModel);
      } else {
        return AuthResponse.error(
          response.data['detail'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        return AuthResponse.error(errorData['detail'] ?? 'Registration failed');
      } else {
        return AuthResponse.error('Network error: ${e.message}');
      }
    } catch (e) {
      return AuthResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  // Login User
  static Future<AuthResponse> loginUser(
    String username,
    String password,
  ) async {
    try {
      _initializeDio();

      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {'username': username, 'password': password},
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      if (response.statusCode == 200) {
        final authModel = AuthModel.fromJson(response.data);
        return AuthResponse.success(authModel);
      } else {
        return AuthResponse.error(response.data['detail'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        return AuthResponse.error(errorData['detail'] ?? 'Invalid credentials');
      } else {
        return AuthResponse.error('Network error: ${e.message}');
      }
    } catch (e) {
      return AuthResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  // Logout User
  static Future<bool> logoutUser(String token) async {
    try {
      _initializeDio();

      final response = await _dio.post(
        ApiConstants.logoutEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Logout error: ${e.message}');
      return false;
    } catch (e) {
      print('Logout unexpected error: ${e.toString()}');
      return false;
    }
  }

  // Validate input
  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Helper method to get Dio instance with auth token
  static Dio getDioWithAuth(String token) {
    final dio = Dio();
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    return dio;
  }
}
