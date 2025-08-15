import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../constants/ApiConstant.dart';
import '../utils/SessionManager.dart';
import '../models/FileModels.dart';
import 'cache_manager.dart';

class FileManagementService {
  static final Dio _dio = Dio();

  // File upload endpoints - SIMPLIFIED (only regular upload)
  static const String _uploadEndpoint = '/files/upload-api';

  // File management endpoints
  static const String _downloadEndpoint = '/files/download';
  static const String _previewEndpoint = '/files/api/preview';
  static const String _deleteEndpoint = '/files/delete';
  static const String _togglePrivacyEndpoint = '/files/toggle-privacy';
  static const String _deleteAllEndpoint = '/files/delete-all';

  // File size limits - SIMPLIFIED (no chunked upload)
  static const int maxFileLimit = 500 * 1024 * 1024; // 500MB max

  // Initialize Dio with base configuration
  static void _initializeDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(
      seconds: 60,
    ); // Increased timeout
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
  }

  // ==================== SIMPLE FILE UPLOAD (Up to 500MB) ====================

  /// Upload file directly - FIXED VERSION
  static Future<FileUploadResponse> uploadFile(
    File file, {
    int ttl = 0,
    bool isPublic = false,
    Function(double progress)? onProgress,
  }) async {
    try {
      _initializeDio();

      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final fileSize = await file.length();
      if (fileSize > maxFileLimit) {
        throw Exception('File too large. Maximum size is 500MB');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'ttl': ttl.toString(),
        'is_public': isPublic
            .toString()
            .toLowerCase(), // Fix: lowercase boolean
      });

      final response = await _dio.post(
        _uploadEndpoint,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        return FileUploadResponse.fromJson(response.data);
      } else {
        throw Exception('Upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMsg = e.response!.data['message'] ?? 'Upload failed';
          throw Exception(errorMsg);
        } else {
          throw Exception('Network error: ${e.message}');
        }
      }
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  // ==================== FILE MANAGEMENT ====================

  /// Download file
  static Future<Uint8List> downloadFile(String fileId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}$_downloadEndpoint/$fileId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        throw Exception('Failed to download file: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  /// Delete file
  static Future<FileDeleteResponse> deleteFile(String fileId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/files/delete/$fileId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return FileDeleteResponse(
          success: true,
          message: 'File deleted successfully',
          fileId: fileId,
        );
      } else {
        throw Exception('Failed to delete file: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 302) {
          return FileDeleteResponse(
            success: true,
            message: 'File deleted successfully',
            fileId: fileId,
          );
        }
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Toggle file privacy
  static Future<FilePrivacyResponse> toggleFilePrivacy(String fileId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/files/toggle-privacy/$fileId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return FilePrivacyResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to toggle file privacy: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to toggle file privacy: ${e.toString()}');
    }
  }

  /// Get file preview/metadata
  static Future<FilePreview> getFilePreview(String fileId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}$_previewEndpoint/$fileId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return FilePreview.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to get file preview: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to get file preview: ${e.toString()}');
    }
  }

  /// Delete all user files
  static Future<DeleteAllResponse> deleteAllFiles() async {
    try {
      _initializeDio();

      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        _deleteAllEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return DeleteAllResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to delete all files: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to delete all files: ${e.toString()}');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file type from filename
  static AppFileType getFileType(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return AppFileType.image;

      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'mkv':
        return AppFileType.video;

      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
      case 'wma':
        return AppFileType.audio;

      case 'pdf':
        return AppFileType.pdf;

      case 'doc':
      case 'docx':
      case 'rtf':
      case 'odt':
        return AppFileType.document;

      case 'xls':
      case 'xlsx':
      case 'ods':
      case 'csv':
        return AppFileType.spreadsheet;

      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return AppFileType.archive;

      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'html':
        return AppFileType.text;

      default:
        return AppFileType.unknown;
    }
  }

  // ==================== FILE LISTING ====================

  /// Get user files
  static Future<UserFilesResponse> getUserFiles({
    int limit = 100,
    int offset = 0,
    String? fileType,
    String? searchQuery,
  }) async {
    try {
      _initializeDio();

      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};

      if (fileType != null) queryParams['file_type'] = fileType;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search_query'] = searchQuery;
      }

      final response = await _dio.get(
        '/files/api/user-files',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final userFilesResponse = UserFilesResponse.fromJson(response.data);
        await CacheManager.cacheUserStats(userFilesResponse.userStats);
        await CacheManager.cacheUserInfo(userFilesResponse.userInfo);
        return userFilesResponse;
      } else {
        throw Exception('Failed to get files: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to get files: ${e.toString()}');
    }
  }
}

// Custom FileType enum to avoid conflict
enum AppFileType {
  image,
  video,
  audio,
  pdf,
  document,
  spreadsheet,
  archive,
  text,
  unknown,
}
