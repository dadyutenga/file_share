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
    if (fileType != AppFileType.image) return;

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
        backgroundColor: Colors.white,
        title: const Text(
          'Delete File',
          style: TextStyle(color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.file.filename}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF757575)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildFilePreview()),
            _buildFileInfo(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.file.filename,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: _showFileDetails,
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    final fileType = _getFileTypeFromCategory(widget.file.fileCategory);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: _buildPreviewContent(fileType),
      ),
    );
  }

  Widget _buildPreviewContent(AppFileType fileType) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF007AFF)),
              SizedBox(height: 20),
              Text(
                'Loading preview...',
                style: TextStyle(color: Color(0xFF757575), fontSize: 16),
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
              Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 64),
              const SizedBox(height: 20),
              Text(
                'Preview not available',
                style: TextStyle(color: Color(0xFF757575), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    switch (fileType) {
      case AppFileType.image:
        return _buildImagePreview();
      case AppFileType.video:
        return _buildVideoPreview();
      default:
        return _buildGenericPreview(fileType);
    }
  }

  Widget _buildImagePreview() {
    if (_fileData == null) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 450),
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

  Widget _buildGenericPreview(AppFileType fileType) {
    final iconColor = _getFileTypeColor(fileType);
    final iconData = _getFileTypeIconData(fileType);
    final typeName = _getFileTypeDisplayName(fileType);

    return SizedBox(
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(iconData, color: iconColor, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              typeName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download to view this file',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.file.filename,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Uploaded ${_getUploadTime()}',
            style: const TextStyle(color: Color(0xFF757575), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Size', widget.file.formattedSize),
              ),
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Format',
                  widget.file.filename.split('.').last.toUpperCase(),
                ),
              ),
              const SizedBox(width: 16),
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
        Text(
          label,
          style: const TextStyle(color: Color(0xFF757575), fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  onPressed: _isDownloading ? null : _downloadFile,
                  isLoading: _isDownloading,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_rounded,
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
              icon: Icons.delete_outline_rounded,
              label: 'Delete File',
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              isLoading: _isDeleting,
              isPrimary: false,
              isDestructive: true,
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
    bool isDestructive = false,
  }) {
    final Color bgColor;
    final Color fgColor;
    final Color disabledBgColor;

    if (isDestructive) {
      bgColor = const Color(0xFF442929);
      fgColor = const Color(0xFFFF6464);
      disabledBgColor = const Color(0x80442929); // 50% opacity of 0xFF442929
    } else if (isPrimary) {
      bgColor = const Color(0xFF007AFF);
      fgColor = Colors.white;
      disabledBgColor = const Color(0x80007AFF); // 50% opacity of 0xFF007AFF
    } else {
      bgColor = const Color(0xFFF5F5F5); // Light grey for light theme
      fgColor = Colors.black87;
      disabledBgColor = const Color(0x80F5F5F5); // 50% opacity of 0xFFF5F5F5
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        disabledBackgroundColor: disabledBgColor,
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
        backgroundColor: Colors.white,
        title: const Text(
          'File Details',
          style: TextStyle(color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods - Fixed to use AppFileType
  AppFileType _getFileTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'image':
        return AppFileType.image;
      case 'video':
        return AppFileType.video;
      case 'document':
        return AppFileType.document;
      case 'audio':
        return AppFileType.audio;
      default:
        return AppFileType.unknown;
    }
  }

  Color _getFileTypeColor(AppFileType fileType) {
    switch (fileType) {
      case AppFileType.image:
        return const Color(0xFF50C878);
      case AppFileType.video:
        return const Color(0xFFB19CD9);
      case AppFileType.audio:
        return const Color(0xFFFFE135);
      case AppFileType.pdf:
        return const Color(0xFF4A90E2);
      case AppFileType.document:
        return const Color(0xFF007AFF);
      case AppFileType.spreadsheet:
        return const Color(0xFF34C759);
      case AppFileType.archive:
        return const Color(0xFFFF9500);
      case AppFileType.text:
        return const Color(0xFF5AC8FA);
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIconData(AppFileType fileType) {
    switch (fileType) {
      case AppFileType.image:
        return Icons.image_rounded;
      case AppFileType.video:
        return Icons.videocam_rounded;
      case AppFileType.audio:
        return Icons.music_note_rounded;
      case AppFileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AppFileType.document:
        return Icons.description_rounded;
      case AppFileType.spreadsheet:
        return Icons.table_chart_rounded;
      case AppFileType.archive:
        return Icons.archive_rounded;
      case AppFileType.text:
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getFileTypeDisplayName(AppFileType fileType) {
    switch (fileType) {
      case AppFileType.image:
        return 'Image';
      case AppFileType.video:
        return 'Video';
      case AppFileType.audio:
        return 'Audio';
      case AppFileType.pdf:
        return 'PDF';
      case AppFileType.document:
        return 'Document';
      case AppFileType.spreadsheet:
        return 'Spreadsheet';
      case AppFileType.archive:
        return 'Archive';
      case AppFileType.text:
        return 'Text';
      default:
        return 'File';
    }
  }
}
