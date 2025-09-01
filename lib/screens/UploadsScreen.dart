import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';
import 'UploadProgressScreen.dart';

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

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final List<SelectedFile> _selectedFiles = [];
  bool _isPickingFiles = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _selectedFiles.isEmpty
          ? _buildFloatingActionButton()
          : null, // Hide FAB when files are selected to prevent overlap
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Upload Files',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_selectedFiles.isNotEmpty)
          TextButton(
            onPressed: _clearAllFiles,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF007AFF),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const StadiumBorder(),
            ),
            child: const Text('Clear All'),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_selectedFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildUploadSummary(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              return _buildFileCard(_selectedFiles[index], index);
            },
          ),
        ),
        _buildUploadButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                size: 70,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Files Selected',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the + button to select files you want to upload.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildSelectFilesButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectFilesButton() {
    return ElevatedButton.icon(
      onPressed: _isPickingFiles ? null : _pickFiles,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      icon: _isPickingFiles
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add_circle_outline_rounded, size: 22),
      label: Text(
        _isPickingFiles ? 'Selecting...' : 'Select Files',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildUploadSummary() {
    final totalSize = _selectedFiles.fold<int>(
      0,
      (sum, file) => sum + file.size,
    );
    final pendingCount = _selectedFiles
        .where((f) => f.uploadStatus == UploadStatus.pending)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedFiles.length} ${_selectedFiles.length == 1 ? "file" : "files"} selected',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total size: ${FileManagementService.formatFileSize(totalSize)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pendingCount pending',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileCard(SelectedFile file, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12.0),
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
        border: Border.all(
          color: _getStatusColor(file.uploadStatus).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.fileType).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: _getFileTypeColor(file.fileType),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    file.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        FileManagementService.formatFileSize(file.size),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          file.uploadStatus,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(file.uploadStatus),
                        style: TextStyle(
                          color: _getStatusColor(file.uploadStatus),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final pendingFiles = _selectedFiles
        .where((f) => f.uploadStatus == UploadStatus.pending)
        .toList();

    if (pendingFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _uploadAllFiles,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          icon: const Icon(Icons.upload_rounded, size: 22),
          label: Text(
            'Upload ${pendingFiles.length} ${pendingFiles.length == 1 ? 'File' : 'Files'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _isPickingFiles ? null : _pickFiles,
      backgroundColor: const Color(0xFF007AFF),
      elevation: 2,
      shape: const CircleBorder(),
      child: _isPickingFiles
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add_rounded, color: Colors.white, size: 32),
    );
  }

  // File selection and management methods
  Future<void> _pickFiles() async {
    setState(() {
      _isPickingFiles = true;
    });

    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: file_picker.FileType.any,
      );

      if (result != null) {
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final fileSize = await file.length();

            // Check file size limit
            if (fileSize > FileManagementService.maxFileLimit) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${platformFile.name} is too large (max 500MB)',
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              continue;
            }

            // Check if file already selected
            if (_selectedFiles.any((f) => f.name == platformFile.name)) {
              continue;
            }

            final selectedFile = SelectedFile(
              file: file,
              name: platformFile.name,
              size: fileSize,
              fileType: FileManagementService.getFileType(platformFile.name),
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
        _isPickingFiles = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  Future<void> _uploadAllFiles() async {
    final pendingFiles = _selectedFiles
        .where((file) => file.uploadStatus == UploadStatus.pending)
        .toList();

    if (pendingFiles.isEmpty) return;

    // Show confirmation for large uploads
    final totalSize = pendingFiles.fold<int>(0, (sum, file) => sum + file.size);
    if (totalSize > 100 * 1024 * 1024) {
      final confirmed = await _showLargeUploadDialog(totalSize);
      if (!confirmed) return;
    }

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => UploadProgressScreen(files: pendingFiles),
        ),
      );

      if (result == true && mounted) {
        setState(() {
          _selectedFiles.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Upload completed! Check your files in the Recent tab.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _showLargeUploadDialog(int totalSize) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Large Upload',
              style: TextStyle(color: Colors.black87),
            ),
            content: Text(
              'You are about to upload ${FileManagementService.formatFileSize(totalSize)} of data. This may take a while and use significant bandwidth. Continue?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Helper methods
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

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Colors.orange;
      case UploadStatus.uploading:
        return const Color(0xFF007AFF);
      case UploadStatus.processing:
        return const Color(0xFF007AFF);
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
      case UploadStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return 'Pending';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.processing:
        return 'Processing';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.cancelled:
        return 'Cancelled';
    }
  }
}
