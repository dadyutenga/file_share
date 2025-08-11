import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../constants/ApiConstant.dart';
import '../utils/SessionManager.dart';
import '../models/FileModels.dart';
import 'cache_manager.dart'; // Add this import

class FileManagementService {
  static final Dio _dio = Dio();

  // File upload endpoints
  static const String _uploadEndpoint = '/files/upload-api';
  static const String _chunkedUploadStartEndpoint =
      '/files/chunked-upload/start';
  static const String _chunkedUploadChunkEndpoint =
      '/files/chunked-upload/chunk';
  static const String _chunkedUploadCompleteEndpoint =
      '/files/chunked-upload/complete';
  static const String _chunkedUploadCancelEndpoint =
      '/files/chunked-upload/cancel';

  // File management endpoints
  static const String _downloadEndpoint = '/files/download';
  static const String _previewEndpoint = '/files/api/preview';
  static const String _deleteEndpoint = '/files/delete';
  static const String _togglePrivacyEndpoint = '/files/toggle-privacy';
  static const String _deleteAllEndpoint = '/files/delete-all';

  // File size limits
  static const int smallFileLimit = 50 * 1024 * 1024; // 50MB
  static const int maxFileLimit = 500 * 1024 * 1024; // 500MB
  static const int chunkSize = 2 * 1024 * 1024; // 2MB chunks

  // Initialize Dio with base configuration
  static void _initializeDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Get headers with auth token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SessionManager.getToken();
    return {'Authorization': 'Bearer $token'};
  }

  // ==================== FILE SELECTION ====================

  /// Pick a file using file picker
  static Future<file_picker.FilePickerResult?> pickFile({
    file_picker.FileType type = file_picker.FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      return await file_picker.FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // ==================== SMALL FILE UPLOAD (Up to 50MB) ====================

  /// Upload small files (up to 50MB) directly
  static Future<FileUploadResponse> uploadSmallFile(
    File file, {
    int ttl = 0,
    bool isPublic = false,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'ttl': ttl.toString(),
        'is_public': isPublic.toString(),
      });

      final response = await _dio.post(
        _uploadEndpoint,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return FileUploadResponse.fromJson(response.data);
      } else {
        throw Exception('Upload failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Upload failed: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  // ==================== CHUNKED UPLOAD (50MB to 500MB) ====================

  /// Start chunked upload for large files
  static Future<ChunkedUploadStartResponse> startChunkedUpload(
    String filename,
    int fileSize,
    int totalChunks, {
    int ttl = 0,
    bool isPublic = false,
  }) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      final response = await _dio.post(
        _chunkedUploadStartEndpoint,
        data: {
          'filename': filename,
          'file_size': fileSize.toString(),
          'total_chunks': totalChunks.toString(),
          'ttl': ttl.toString(),
          'is_public': isPublic.toString(),
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return ChunkedUploadStartResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to start upload: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Start upload failed: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Upload a single chunk
  static Future<ChunkUploadResponse> uploadChunk(
    String uploadId,
    int chunkNumber,
    Uint8List chunkData,
  ) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      FormData formData = FormData.fromMap({
        'upload_id': uploadId,
        'chunk_number': chunkNumber.toString(),
        'chunk': MultipartFile.fromBytes(
          chunkData,
          filename: 'chunk_$chunkNumber',
        ),
      });

      final response = await _dio.post(
        _chunkedUploadChunkEndpoint,
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return ChunkUploadResponse.fromJson(response.data);
      } else {
        throw Exception('Chunk upload failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Chunk upload failed: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Complete chunked upload
  static Future<FileUploadResponse> completeChunkedUpload(
    String uploadId, {
    int ttl = 0,
    bool isPublic = false,
  }) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      final response = await _dio.post(
        _chunkedUploadCompleteEndpoint,
        data: {
          'upload_id': uploadId,
          'ttl': ttl.toString(),
          'is_public': isPublic.toString(),
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return FileUploadResponse.fromJson(response.data);
      } else {
        throw Exception('Complete upload failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Complete upload failed: ${e.response!.data['message']}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Cancel chunked upload
  static Future<void> cancelChunkedUpload(String uploadId) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      await _dio.delete(
        _chunkedUploadCancelEndpoint,
        data: {'upload_id': uploadId},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw Exception('Cancel upload failed: ${e.message}');
    }
  }

  // ==================== SMART UPLOAD ====================

  /// Smart upload - automatically chooses between small or chunked upload
  static Future<FileUploadResponse> uploadFile(
    File file, {
    int ttl = 0,
    bool isPublic = false,
    Function(double progress)? onProgress,
  }) async {
    final fileSize = await file.length();

    if (fileSize > maxFileLimit) {
      throw Exception('File too large. Maximum size is 500MB');
    }

    if (fileSize <= smallFileLimit) {
      // Use direct upload for small files
      return await uploadSmallFile(
        file,
        ttl: ttl,
        isPublic: isPublic,
        onProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent / total);
          }
        },
      );
    } else {
      // Use chunked upload for large files
      return await _uploadLargeFile(
        file,
        ttl: ttl,
        isPublic: isPublic,
        onProgress: onProgress,
      );
    }
  }

  /// Handle large file chunked upload with progress
  static Future<FileUploadResponse> _uploadLargeFile(
    File file, {
    int ttl = 0,
    bool isPublic = false,
    Function(double progress)? onProgress,
  }) async {
    final fileSize = await file.length();
    final totalChunks = (fileSize / chunkSize).ceil();
    final filename = file.path.split('/').last;

    // Start chunked upload
    final startResponse = await startChunkedUpload(
      filename,
      fileSize,
      totalChunks,
      ttl: ttl,
      isPublic: isPublic,
    );

    try {
      // Upload chunks
      final fileBytes = await file.readAsBytes();

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize < fileSize)
            ? start + chunkSize
            : fileSize;
        final chunkData = fileBytes.sublist(start, end);

        await uploadChunk(
          startResponse.uploadId,
          i,
          Uint8List.fromList(chunkData),
        );

        // Update progress
        if (onProgress != null) {
          onProgress((i + 1) / totalChunks);
        }
      }

      // Complete upload
      return await completeChunkedUpload(
        startResponse.uploadId,
        ttl: ttl,
        isPublic: isPublic,
      );
    } catch (e) {
      // Cancel upload on error
      await cancelChunkedUpload(startResponse.uploadId);
      rethrow;
    }
  }

  // ==================== FILE MANAGEMENT ====================

  /// Download file
  static Future<Uint8List> downloadFile(String fileId) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.get(
        '$_downloadEndpoint/$fileId',
        options: Options(headers: headers, responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        throw Exception('Download failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Download failed: ${e.response!.statusMessage}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Get file preview/metadata
  static Future<FilePreview> getFilePreview(String fileId) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.get(
        '$_previewEndpoint/$fileId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return FilePreview.fromJson(response.data);
      } else {
        throw Exception('Preview failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Preview failed: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Delete file
  static Future<FileDeleteResponse> deleteFile(String fileId) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        '$_deleteEndpoint/$fileId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return FileDeleteResponse.fromJson(response.data);
      } else {
        throw Exception('Delete failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Delete failed: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Toggle file privacy
  static Future<FilePrivacyResponse> toggleFilePrivacy(String fileId) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        '$_togglePrivacyEndpoint/$fileId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return FilePrivacyResponse.fromJson(response.data);
      } else {
        throw Exception('Toggle privacy failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Toggle privacy failed: ${e.response!.data['message']}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Delete all user files
  static Future<DeleteAllResponse> deleteAllFiles() async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        _deleteAllEndpoint,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return DeleteAllResponse.fromJson(response.data);
      } else {
        throw Exception('Delete all failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Delete all failed: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
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

  /// Get file extension
  static String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  /// Get file type using FileTypeHelper from models
  static FileType getFileType(String filename) {
    return FileTypeHelper.getFileType(filename);
  }

  /// Get file type icon using FileTypeHelper from models
  static String getFileTypeIcon(String filename) {
    final fileType = FileTypeHelper.getFileType(filename);
    return FileTypeHelper.getFileTypeIcon(fileType);
  }

  /// Get file type display name using FileTypeHelper from models
  static String getFileTypeDisplayName(String filename) {
    final fileType = FileTypeHelper.getFileType(filename);
    return FileTypeHelper.getFileTypeDisplayName(fileType);
  }

  // ==================== FILE LISTING ====================

  /// Get user files using the new API endpoint
  static Future<UserFilesResponse> getUserFiles({
    int limit = 100,
    int offset = 0,
    String? fileType,
    String? searchQuery,
  }) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};

      if (fileType != null) queryParams['file_type'] = fileType;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search_query'] = searchQuery;
      }

      final response = await _dio.get(
        '/files/api/user-files', // Correct endpoint
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final userFilesResponse = UserFilesResponse.fromJson(response.data);

        // Cache the user stats and info
        await CacheManager.cacheUserStats(userFilesResponse.userStats);
        await CacheManager.cacheUserInfo(userFilesResponse.userInfo);

        return userFilesResponse;
      } else {
        throw Exception('Failed to get files: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to get files: ${e.response!.statusMessage}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to parse response: ${e.toString()}');
    }
  }

  /// Get files by category
  static Future<UserFilesResponse> getFilesByCategory(
    String category, {
    int limit = 100,
    int offset = 0,
  }) async {
    return await getUserFiles(limit: limit, offset: offset, fileType: category);
  }

  /// Search files
  static Future<UserFilesResponse> searchFiles(
    String query, {
    int limit = 100,
    int offset = 0,
    String? fileType,
  }) async {
    return await getUserFiles(
      limit: limit,
      offset: offset,
      fileType: fileType,
      searchQuery: query,
    );
  }

  /// Load next page
  static Future<UserFilesResponse> loadNextPage(
    UserFilesResponse currentResponse,
  ) async {
    if (!currentResponse.pagination.hasNext) {
      return currentResponse; // No more pages
    }

    return await getUserFiles(
      limit: currentResponse.pagination.limit,
      offset:
          currentResponse.pagination.offset + currentResponse.pagination.limit,
    );
  }

  // ==================== BATCH OPERATIONS ====================

  /// Delete multiple files
  static Future<ApiResponse<Map<String, dynamic>>> deleteMultipleFiles(
    List<String> fileIds,
  ) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        '/files/delete-multiple', // Update this endpoint when available
        data: {'file_ids': fileIds},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          'Failed to delete files: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.error(
          'Failed to delete files: ${e.response!.data['message']}',
        );
      } else {
        return ApiResponse.error('Network error: ${e.message}');
      }
    }
  }

  /// Toggle privacy for multiple files
  static Future<ApiResponse<Map<String, dynamic>>> toggleMultipleFilesPrivacy(
    List<String> fileIds,
    bool isPublic,
  ) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        '/files/toggle-multiple-privacy', // Update this endpoint when available
        data: {'file_ids': fileIds, 'is_public': isPublic},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          'Failed to update privacy: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.error(
          'Failed to update privacy: ${e.response!.data['message']}',
        );
      } else {
        return ApiResponse.error('Network error: ${e.message}');
      }
    }
  }
}
