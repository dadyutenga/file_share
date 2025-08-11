// File upload response model
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

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'file_id': fileId,
      'download_url': downloadUrl,
      'preview_url': previewUrl,
      'filename': filename,
      'file_size': fileSize,
      'is_public': isPublic,
    };
  }
}

// Chunked upload start response model
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

  Map<String, dynamic> toJson() {
    return {
      'upload_id': uploadId,
      'status': status,
      'message': message,
      'chunk_size': chunkSize,
    };
  }
}

// Chunk upload response model
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

  Map<String, dynamic> toJson() {
    return {
      'chunk_number': chunkNumber,
      'status': status,
      'upload_complete': uploadComplete,
      'message': message,
    };
  }
}

// File preview/metadata model
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

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'content_type': contentType,
      'upload_time': uploadTime,
      'download_count': downloadCount,
      'is_public': isPublic,
      'ttl': ttl,
      'owner_username': ownerUsername,
      'file_type': fileType,
      'preview_available': previewAvailable,
    };
  }

  // Helper methods
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024)
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileExtension {
    return originalFilename.split('.').last.toLowerCase();
  }

  DateTime? get uploadDateTime {
    try {
      return DateTime.parse(uploadTime);
    } catch (e) {
      return null;
    }
  }

  String get formattedUploadTime {
    final dateTime = uploadDateTime;
    if (dateTime == null) return uploadTime;

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// File privacy toggle response model
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

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'is_public': isPublic};
  }
}

// Delete all files response model
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

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'deleted_count': deletedCount,
    };
  }
}

// File delete response model
class FileDeleteResponse {
  final bool success;
  final String message;

  FileDeleteResponse({required this.success, required this.message});

  factory FileDeleteResponse.fromJson(Map<String, dynamic> json) {
    return FileDeleteResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message};
  }
}

// File download info model
class FileDownloadInfo {
  final String fileId;
  final String filename;
  final int fileSize;
  final String contentType;
  final bool isPublic;

  FileDownloadInfo({
    required this.fileId,
    required this.filename,
    required this.fileSize,
    required this.contentType,
    required this.isPublic,
  });

  factory FileDownloadInfo.fromJson(Map<String, dynamic> json) {
    return FileDownloadInfo(
      fileId: json['file_id'] ?? '',
      filename: json['filename'] ?? '',
      fileSize: json['file_size'] ?? 0,
      contentType: json['content_type'] ?? '',
      isPublic: json['is_public'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'filename': filename,
      'file_size': fileSize,
      'content_type': contentType,
      'is_public': isPublic,
    };
  }
}

// Upload progress model
class UploadProgress {
  final String uploadId;
  final String filename;
  final double progress; // 0.0 to 1.0
  final int uploadedBytes;
  final int totalBytes;
  final UploadStatus status;
  final String? errorMessage;

  UploadProgress({
    required this.uploadId,
    required this.filename,
    required this.progress,
    required this.uploadedBytes,
    required this.totalBytes,
    required this.status,
    this.errorMessage,
  });

  UploadProgress copyWith({
    String? uploadId,
    String? filename,
    double? progress,
    int? uploadedBytes,
    int? totalBytes,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return UploadProgress(
      uploadId: uploadId ?? this.uploadId,
      filename: filename ?? this.filename,
      progress: progress ?? this.progress,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get formattedProgress {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024)
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024)
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Upload status enum
enum UploadStatus {
  pending,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

// File type enum
enum FileType {
  image,
  video,
  audio,
  document,
  pdf,
  spreadsheet,
  archive,
  text,
  unknown,
}

// File type helper class
class FileTypeHelper {
  static FileType getFileType(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return FileType.image;

      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'mkv':
        return FileType.video;

      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'ogg':
      case 'm4a':
        return FileType.audio;

      case 'pdf':
        return FileType.pdf;

      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return FileType.document;

      case 'xls':
      case 'xlsx':
      case 'ods':
      case 'csv':
        return FileType.spreadsheet;

      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return FileType.archive;

      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'html':
      case 'css':
      case 'js':
        return FileType.text;

      default:
        return FileType.unknown;
    }
  }

  static String getFileTypeIcon(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return 'image';
      case FileType.video:
        return 'video';
      case FileType.audio:
        return 'audio';
      case FileType.pdf:
        return 'pdf';
      case FileType.document:
        return 'document';
      case FileType.spreadsheet:
        return 'spreadsheet';
      case FileType.archive:
        return 'archive';
      case FileType.text:
        return 'text';
      case FileType.unknown:
      default:
        return 'file';
    }
  }

  static String getFileTypeDisplayName(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return 'Image';
      case FileType.video:
        return 'Video';
      case FileType.audio:
        return 'Audio';
      case FileType.pdf:
        return 'PDF';
      case FileType.document:
        return 'Document';
      case FileType.spreadsheet:
        return 'Spreadsheet';
      case FileType.archive:
        return 'Archive';
      case FileType.text:
        return 'Text';
      case FileType.unknown:
      default:
        return 'File';
    }
  }
}

// File list response model (for future use with file listing endpoints)
class FileListResponse {
  final bool success;
  final String message;
  final List<FilePreview> files;
  final int totalFiles;
  final int page;
  final int pageSize;
  final bool hasMore;

  FileListResponse({
    required this.success,
    required this.message,
    required this.files,
    required this.totalFiles,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    return FileListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      files:
          (json['files'] as List<dynamic>?)
              ?.map((file) => FilePreview.fromJson(file))
              .toList() ??
          [],
      totalFiles: json['total_files'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      hasMore: json['has_more'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'files': files.map((file) => file.toJson()).toList(),
      'total_files': totalFiles,
      'page': page,
      'page_size': pageSize,
      'has_more': hasMore,
    };
  }
}

// Error response model
class FileOperationError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  FileOperationError({required this.code, required this.message, this.details});

  factory FileOperationError.fromJson(Map<String, dynamic> json) {
    return FileOperationError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'An unknown error occurred',
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
    };
  }

  @override
  String toString() {
    return 'FileOperationError(code: $code, message: $message)';
  }
}

// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final FileOperationError? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data, {String message = 'Success'}) {
    return ApiResponse(success: true, message: message, data: data);
  }

  factory ApiResponse.error(String message, {FileOperationError? error}) {
    return ApiResponse(success: false, message: message, error: error);
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
}

// User Files API Response Model
class UserFilesResponse {
  final bool success;
  final List<FileItem> files;
  final Pagination pagination;
  final Filters filters;
  final UserStats userStats;
  final UserInfo userInfo;

  UserFilesResponse({
    required this.success,
    required this.files,
    required this.pagination,
    required this.filters,
    required this.userStats,
    required this.userInfo,
  });

  factory UserFilesResponse.fromJson(Map<String, dynamic> json) {
    return UserFilesResponse(
      success: json['success'] ?? false,
      files:
          (json['files'] as List?)
              ?.map((file) => FileItem.fromJson(file))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      filters: Filters.fromJson(json['filters'] ?? {}),
      userStats: UserStats.fromJson(json['user_stats'] ?? {}),
      userInfo: UserInfo.fromJson(json['user_info'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'files': files.map((file) => file.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters': filters.toJson(),
      'user_stats': userStats.toJson(),
      'user_info': userInfo.toJson(),
    };
  }
}

// File Item Model (from the new API)
class FileItem {
  final String fileId;
  final String filename;
  final int fileSize;
  final String formattedSize;
  final String? contentType;
  final String fileCategory;
  final bool isPublic;
  final bool isExpired;
  final String? uploadDate;
  final int ttl;
  final String downloadUrl;
  final String previewUrl;
  final String? fileHash;
  final int downloadCount;

  FileItem({
    required this.fileId,
    required this.filename,
    required this.fileSize,
    required this.formattedSize,
    this.contentType,
    required this.fileCategory,
    required this.isPublic,
    required this.isExpired,
    this.uploadDate,
    required this.ttl,
    required this.downloadUrl,
    required this.previewUrl,
    this.fileHash,
    required this.downloadCount,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json['file_id'] ?? '',
      filename: json['filename'] ?? '',
      fileSize: json['file_size'] ?? 0,
      formattedSize: json['formatted_size'] ?? '0 B',
      contentType: json['content_type'],
      fileCategory: json['file_category'] ?? 'other',
      isPublic: json['is_public'] ?? false,
      isExpired: json['is_expired'] ?? false,
      uploadDate: json['upload_date'],
      ttl: json['ttl'] ?? 0,
      downloadUrl: json['download_url'] ?? '',
      previewUrl: json['preview_url'] ?? '',
      fileHash: json['file_hash'],
      downloadCount: json['download_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'filename': filename,
      'file_size': fileSize,
      'formatted_size': formattedSize,
      'content_type': contentType,
      'file_category': fileCategory,
      'is_public': isPublic,
      'is_expired': isExpired,
      'upload_date': uploadDate,
      'ttl': ttl,
      'download_url': downloadUrl,
      'preview_url': previewUrl,
      'file_hash': fileHash,
      'download_count': downloadCount,
    };
  }

  // Helper methods
  DateTime? get uploadDateTime {
    try {
      return uploadDate != null ? DateTime.parse(uploadDate!) : null;
    } catch (e) {
      return null;
    }
  }

  String get formattedUploadTime {
    final dateTime = uploadDateTime;
    if (dateTime == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get fileExtension {
    return filename.split('.').last.toLowerCase();
  }
}

// Pagination Model
class Pagination {
  final int totalCount;
  final int limit;
  final int offset;
  final bool hasNext;
  final bool hasPrevious;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.totalCount,
    required this.limit,
    required this.offset,
    required this.hasNext,
    required this.hasPrevious,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalCount: json['total_count'] ?? 0,
      limit: json['limit'] ?? 100,
      offset: json['offset'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'limit': limit,
      'offset': offset,
      'has_next': hasNext,
      'has_previous': hasPrevious,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }
}

// Filters Model
class Filters {
  final String? fileType;
  final String? searchQuery;

  Filters({this.fileType, this.searchQuery});

  factory Filters.fromJson(Map<String, dynamic> json) {
    return Filters(
      fileType: json['file_type'],
      searchQuery: json['search_query'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'file_type': fileType, 'search_query': searchQuery};
  }
}

// User Stats Model (for caching and settings page)
class UserStats {
  final int userId;
  final String? username;
  final int storageLimit;
  final String formattedStorageLimit;
  final int storageUsed;
  final String formattedStorageUsed;
  final int storageAvailable;
  final double storagePercentage;
  final int dailyDownloadLimit;
  final String formattedDownloadLimit;
  final int dailyDownloadsUsed;
  final double dailyDownloadPercentage;
  final int totalFiles;
  final int totalDownloads;

  UserStats({
    required this.userId,
    this.username,
    required this.storageLimit,
    required this.formattedStorageLimit,
    required this.storageUsed,
    required this.formattedStorageUsed,
    required this.storageAvailable,
    required this.storagePercentage,
    required this.dailyDownloadLimit,
    required this.formattedDownloadLimit,
    required this.dailyDownloadsUsed,
    required this.dailyDownloadPercentage,
    required this.totalFiles,
    required this.totalDownloads,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] ?? 0,
      username: json['username'],
      storageLimit: json['storage_limit'] ?? 0,
      formattedStorageLimit: json['formatted_storage_limit'] ?? '0 B',
      storageUsed: json['storage_used'] ?? 0,
      formattedStorageUsed: json['formatted_storage_used'] ?? '0 B',
      storageAvailable: json['storage_available'] ?? 0,
      storagePercentage: (json['storage_percentage'] ?? 0.0).toDouble(),
      dailyDownloadLimit: json['daily_download_limit'] ?? 0,
      formattedDownloadLimit: json['formatted_download_limit'] ?? '0 B',
      dailyDownloadsUsed: json['daily_downloads_used'] ?? 0,
      dailyDownloadPercentage: (json['daily_download_percentage'] ?? 0.0)
          .toDouble(),
      totalFiles: json['total_files'] ?? 0,
      totalDownloads: json['total_downloads'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'storage_limit': storageLimit,
      'formatted_storage_limit': formattedStorageLimit,
      'storage_used': storageUsed,
      'formatted_storage_used': formattedStorageUsed,
      'storage_available': storageAvailable,
      'storage_percentage': storagePercentage,
      'daily_download_limit': dailyDownloadLimit,
      'formatted_download_limit': formattedDownloadLimit,
      'daily_downloads_used': dailyDownloadsUsed,
      'daily_download_percentage': dailyDownloadPercentage,
      'total_files': totalFiles,
      'total_downloads': totalDownloads,
    };
  }
}

// User Info Model
class UserInfo {
  final int userId;
  final String? username;

  UserInfo({required this.userId, this.username});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(userId: json['user_id'] ?? 0, username: json['username']);
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'username': username};
  }
}
