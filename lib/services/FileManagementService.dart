import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/ApiConstant.dart';
import '../utils/SessionManager.dart';
import '../models/FileModels.dart';

class FileManagementService {
  static final Dio _dio = Dio();

  // File upload endpoints
  static const String _uploadEndpoint = '/files/upload-api';
  static const String _chunkedUploadStartEndpoint = '/files/chunked-upload/start';
  static const String _chunkedUploadChunkEndpoint = '/files/chunked-upload/chunk';
  static const String _chunkedUploadCompleteEndpoint = '/files/chunked-upload/complete';
  static const String _chunkedUploadCancelEndpoint = '/files/chunked-upload/cancel';

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
  static Future<FilePickerResult?> pickFile({
    file_picker.FileType type = file_picker.FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      return await FilePicker.platform.pickFiles(
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
        throw Exception('Complete upload failed: ${e.response!.data['message']}');
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
        final end = (start + chunkSize < fileSize) ? start + chunkSize : fileSize;
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
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
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
        throw Exception('Toggle privacy failed: ${e.response!.data['message']}');
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

  /// Format file size - now uses the helper from FileModels
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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

  // ==================== FILE LISTING (Future Implementation) ====================

  /// Get user files list (when implemented in backend)
  static Future<FileListResponse> getUserFiles({
    int page = 1,
    int pageSize = 20,
    String? fileType,
    String? searchQuery,
  }) async {
    try {
      _initializeDio();

      final headers = await _getAuthHeaders();

      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (fileType != null) 'file_type': fileType,
        if (searchQuery != null) 'search': searchQuery,
      };

      final response = await _dio.get(
        '/files/list', // Update this endpoint when available
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return FileListResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to get files: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to get files: ${e.response!.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
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
        return ApiResponse.error('Failed to delete files: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.error('Failed to delete files: ${e.response!.data['message']}');
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
        data: {
          'file_ids': fileIds,
          'is_public': isPublic,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error('Failed to update privacy: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.error('Failed to update privacy: ${e.response!.data['message']}');
      } else {
        return ApiResponse.error('Network error: ${e.message}');
      }
    }
  }
}

// ==================== RESPONSE MODELS ====================

class FileUploadResponse {
  final bool success;
  final String message;
  final String fileId;
  final String downloadUrl;
  final String previewUrl;
  final String filename;
  final int fileSize;
  final bool isPublic;

  FileUploadResponse({
    required this.success,
    required this.message,
    required this.fileId,
    required this.downloadUrl,
    required this.previewUrl,
    required this.filename,
    required this.fileSize,
    required this.isPublic,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      fileId: json['file_id'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      previewUrl: json['preview_url'] ?? '',
      filename: json['filename'] ?? '',
      fileSize: json['file_size'] ?? 0,
      isPublic: json['is_public'] ?? false,
    );
  }
}

class ChunkedUploadStartResponse {
  final String uploadId;
  final String status;
  final String message;
  final int chunkSize;

  ChunkedUploadStartResponse({
    required this.uploadId,
    required this.status,
    required this.message,
    required this.chunkSize,
  });

  factory ChunkedUploadStartResponse.fromJson(Map<String, dynamic> json) {
    return ChunkedUploadStartResponse(
      uploadId: json['upload_id'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      chunkSize: json['chunk_size'] ?? 0,
    );
  }
}

class ChunkUploadResponse {
  final int chunkNumber;
  final String status;
  final bool uploadComplete;
  final String message;

  ChunkUploadResponse({
    required this.chunkNumber,
    required this.status,
    required this.uploadComplete,
    required this.message,
  });

  factory ChunkUploadResponse.fromJson(Map<String, dynamic> json) {
    return ChunkUploadResponse(
      chunkNumber: json['chunk_number'] ?? 0,
      status: json['status'] ?? '',
      uploadComplete: json['upload_complete'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class FilePreview {
  final String fileId;
  final String originalFilename;
  final int fileSize;
  final String contentType;
  final String uploadTime;
  final int downloadCount;
  final bool isPublic;
  final int ttl;
  final String ownerUsername;
  final String fileType;
  final bool previewAvailable;

  FilePreview({
    required this.fileId,
    required this.originalFilename,
    required this.fileSize,
    required this.contentType,
    required this.uploadTime,
    required this.downloadCount,
    required this.isPublic,
    required this.ttl,
    required this.ownerUsername,
    required this.fileType,
    required this.previewAvailable,
  });

  factory FilePreview.fromJson(Map<String, dynamic> json) {
    return FilePreview(
      fileId: json['file_id'] ?? '',
      originalFilename: json['original_filename'] ?? '',
      fileSize: json['file_size'] ?? 0,
      contentType: json['content_type'] ?? '',
      uploadTime: json['upload_time'] ?? '',
      downloadCount: json['download_count'] ?? 0,
      isPublic: json['is_public'] ?? false,
      ttl: json['ttl'] ?? 0,
      ownerUsername: json['owner_username'] ?? '',
      fileType: json['file_type'] ?? '',
      previewAvailable: json['preview_available'] ?? false,
    );
  }
}

class FilePrivacyResponse {
  final bool success;
  final String message;
  final bool isPublic;

  FilePrivacyResponse({
    required this.success,
    required this.message,
    required this.isPublic,
  });

  factory FilePrivacyResponse.fromJson(Map<String, dynamic> json) {
    return FilePrivacyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      isPublic: json['is_public'] ?? false,
    );
  }
}

class DeleteAllResponse {
  final bool success;
  final String message;
  final int deletedCount;

  DeleteAllResponse({
    required this.success,
    required this.message,
    required this.deletedCount,
  });

  factory DeleteAllResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAllResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      deletedCount: json['deleted_count'] ?? 0,
    );
  }
}
