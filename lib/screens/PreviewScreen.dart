import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';

class PreviewScreen extends StatefulWidget {
  final FileItem file;

  const PreviewScreen({super.key, required this.file});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isDeleting = false;
  String? _errorMessage;
  Uint8List? _fileData;

  @override
  void initState() {
    super.initState();
    _loadFilePreview();
  }

  Future<void> _loadFilePreview() async {
    final fileType = _getFileTypeFromCategory(widget.file.fileCategory);

    // Only load preview for images
    if (fileType != FileType.image) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fileData = await FileManagementService.downloadFile(
        widget.file.fileId,
      );
      setState(() {
        _fileData = fileData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load preview: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final permission = await _requestStoragePermission();
      if (!permission) {
        throw Exception('Storage permission denied');
      }

      final fileData = await FileManagementService.downloadFile(
        widget.file.fileId,
      );

      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          downloadsDirectory = await getExternalStorageDirectory();
          downloadsDirectory = Directory(
            '${downloadsDirectory!.path}/Download',
          );
        }
      } else {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      await downloadsDirectory.create(recursive: true);
      final file = File('${downloadsDirectory.path}/${widget.file.filename}');
      await file.writeAsBytes(fileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: ${widget.file.filename}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 30) {
          final status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } catch (e) {
        print('Permission error: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> _shareFile() async {
    try {
      // Use the public URL or download URL - whatever exists in your FileItem
      final shareUrl = widget.file.downloadUrl.isNotEmpty
          ? widget.file.downloadUrl
          : 'Check out this file: ${widget.file.filename}';

      await Share.share(
        shareUrl,
        subject: 'Shared file: ${widget.file.filename}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await FileManagementService.deleteFile(
        widget.file.fileId,
      );

      // Check if delete was successful
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File deleted: ${widget.file.filename}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, 'deleted');
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${widget.file.filename}"? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildFilePreview()),
          _buildFileInfo(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.file.filename,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showFileDetails,
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    final fileType = _getFileTypeFromCategory(widget.file.fileCategory);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: _buildPreviewContent(fileType),
      ),
    );
  }

  Widget _buildPreviewContent(FileType fileType) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF007AFF)),
              SizedBox(height: 16),
              Text(
                'Loading preview...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              const SizedBox(height: 16),
              Text(
                'Preview not available',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    switch (fileType) {
      case FileType.image:
        return _buildImagePreview();
      case FileType.video:
        return _buildVideoPreview();
      default:
        return _buildGenericPreview(fileType);
    }
  }

  Widget _buildImagePreview() {
    if (_fileData == null) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
      child: Image.memory(
        _fileData!,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gradient for video
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFB19CD9).withOpacity(0.3),
                  const Color(0xFF6A4C93).withOpacity(0.7),
                ],
              ),
            ),
            child: const Icon(Icons.movie, color: Colors.white, size: 80),
          ),

          // Video overlay indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam, color: Colors.white, size: 40),
          ),

          // Video info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.file.filename,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB19CD9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getVideoFormat(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.file.formattedSize,
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        'Video File',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVideoFormat() {
    final extension = widget.file.filename.split('.').last.toUpperCase();
    return extension;
  }

  Widget _buildGenericPreview(FileType fileType) {
    final iconColor = _getFileTypeColor(fileType);
    final iconData = _getFileTypeIconData(fileType);
    final typeName = _getFileTypeDisplayName(fileType);

    return Container(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(iconData, color: iconColor, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              typeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download to view this file',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.file.filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Uploaded ${_getUploadTime()}',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Size', widget.file.formattedSize),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Type',
                  _getFileTypeDisplayName(
                    _getFileTypeFromCategory(widget.file.fileCategory),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Format',
                  widget.file.filename.split('.').last.toUpperCase(),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Downloads',
                  '${widget.file.downloadCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUploadTime() {
    try {
      return widget.file.formattedUploadTime;
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onPressed: _isDownloading ? null : _downloadFile,
                  isLoading: _isDownloading,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: _shareFile,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Delete File',
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              isLoading: _isDeleting,
              isPrimary: false,
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isPrimary = false,
    Color? backgroundColor,
  }) {
    final bgColor =
        backgroundColor ??
        (isPrimary ? const Color(0xFF007AFF) : const Color(0xFF2C2C2E));

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  void _showFileDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'File Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File ID', widget.file.fileId),
            _buildDetailRow('Name', widget.file.filename),
            _buildDetailRow('Size', widget.file.formattedSize),
            _buildDetailRow('Type', widget.file.contentType ?? 'Unknown'),
            _buildDetailRow('Category', widget.file.fileCategory),
            _buildDetailRow('Uploaded', _getUploadTime()),
            _buildDetailRow('Downloads', '${widget.file.downloadCount}'),
            _buildDetailRow('Public', widget.file.isPublic ? 'Yes' : 'No'),
            _buildDetailRow('Expired', widget.file.isExpired ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  FileType _getFileTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'image':
        return FileType.image;
      case 'video':
        return FileType.video;
      case 'document':
        return FileType.document;
      case 'audio':
        return FileType.audio;
      default:
        return FileType.unknown;
    }
  }

  Color _getFileTypeColor(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return const Color(0xFF50C878);
      case FileType.video:
        return const Color(0xFFB19CD9);
      case FileType.audio:
        return const Color(0xFFFFE135);
      case FileType.pdf:
        return const Color(0xFF4A90E2);
      case FileType.document:
        return const Color(0xFF007AFF);
      case FileType.spreadsheet:
        return const Color(0xFF34C759);
      case FileType.archive:
        return const Color(0xFFFF9500);
      case FileType.text:
        return const Color(0xFF5AC8FA);
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIconData(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.videocam;
      case FileType.audio:
        return Icons.music_note;
      case FileType.pdf:
        return Icons.description;
      case FileType.document:
        return Icons.description;
      case FileType.spreadsheet:
        return Icons.table_chart;
      case FileType.archive:
        return Icons.archive;
      case FileType.text:
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileTypeDisplayName(FileType fileType) {
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
      default:
        return 'File';
    }
  }
}
