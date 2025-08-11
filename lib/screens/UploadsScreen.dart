import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';
import 'UploadProgressScreen.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  List<SelectedFile> _selectedFiles = [];
  bool _isSelecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFileDropZone(),
                  const SizedBox(height: 30),
                  _buildSelectedFilesSection(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      title: const Text(
        'Upload Files',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: _selectFiles,
        ),
      ],
    );
  }

  Widget _buildFileDropZone() {
    return GestureDetector(
      onTap: _selectFiles,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to select files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Photos, Videos, Documents, etc.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFilesSection() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Files',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedFiles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final file = _selectedFiles[index];
            return _buildFileItem(file, index);
          },
        ),
      ],
    );
  }

  Widget _buildFileItem(SelectedFile file, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getFileTypeColor(file.fileType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getFileTypeColor(file.fileType).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.fileType),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(file.size),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (file.uploadStatus == UploadStatus.completed)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          else if (file.uploadStatus == UploadStatus.failed)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            )
          else
            GestureDetector(
              onTap: () => _removeFile(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canUpload() ? _uploadAllFiles : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Upload All (${_selectedFiles.length} files)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectFiles() async {
    if (_isSelecting) return;

    setState(() {
      _isSelecting = true;
    });

    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: file_picker.FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final fileSize = await file.length();

            // Check file size limit (500MB)
            const maxFileSize = 500 * 1024 * 1024; // 500MB in bytes
            if (fileSize > maxFileSize) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'File ${platformFile.name} is too large. Maximum size is 500MB.',
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              continue;
            }

            final selectedFile = SelectedFile(
              file: file,
              name: platformFile.name,
              size: fileSize,
              fileType: _getFileTypeFromName(platformFile.name),
              uploadStatus: UploadStatus.pending,
            );

            setState(() {
              _selectedFiles.add(selectedFile);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select files: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSelecting = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  bool _canUpload() {
    return _selectedFiles.isNotEmpty &&
        _selectedFiles.any((file) => file.uploadStatus == UploadStatus.pending);
  }

  Future<void> _uploadAllFiles() async {
    final pendingFiles = _selectedFiles
        .where((file) => file.uploadStatus == UploadStatus.pending)
        .toList();

    if (pendingFiles.isEmpty) return;

    // Navigate to upload progress screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => UploadProgressScreen(files: pendingFiles),
      ),
    );

    // Refresh the selected files list based on upload results
    if (result == true && mounted) {
      setState(() {
        // Update upload status for completed files
        for (var file in _selectedFiles) {
          if (file.uploadStatus == UploadStatus.uploading) {
            file.uploadStatus = UploadStatus.completed;
          }
        }
      });
    }
  }

  // Helper method to get file type from filename
  AppFileType _getFileTypeFromName(String filename) {
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

  // Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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

  IconData _getFileTypeIcon(AppFileType fileType) {
    switch (fileType) {
      case AppFileType.image:
        return Icons.image;
      case AppFileType.video:
        return Icons.videocam;
      case AppFileType.audio:
        return Icons.music_note;
      case AppFileType.pdf:
        return Icons.picture_as_pdf;
      case AppFileType.document:
        return Icons.description;
      case AppFileType.spreadsheet:
        return Icons.table_chart;
      case AppFileType.archive:
        return Icons.archive;
      case AppFileType.text:
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// Supporting classes - MOVED TO BOTTOM
class SelectedFile {
  final File file;
  final String name;
  final int size;
  final AppFileType fileType;
  UploadStatus uploadStatus;
  double progress;
  String? uploadId;

  SelectedFile({
    required this.file,
    required this.name,
    required this.size,
    required this.fileType,
    required this.uploadStatus,
    this.progress = 0.0,
    this.uploadId,
  });
}

enum UploadStatus { pending, uploading, completed, failed }

// Custom FileType enum to avoid conflict with FilePicker's FileType
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
