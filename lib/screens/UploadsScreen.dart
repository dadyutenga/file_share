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
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
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
        if (_selectedFiles.isNotEmpty)
          TextButton(
            onPressed: _clearAllFiles,
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 60,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No files selected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the + button to select files to upload',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: _isPickingFiles
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add, size: 20),
      label: Text(
        _isPickingFiles ? 'Selecting...' : 'Select Files',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedFiles.length} files selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total size: ${FileManagementService.formatFileSize(totalSize)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pendingCount pending',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileCard(SelectedFile file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getStatusColor(file.uploadStatus).withOpacity(0.3),
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
                Row(
                  children: [
                    Text(
                      FileManagementService.formatFileSize(file.size),
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          file.uploadStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(file.uploadStatus),
                        style: TextStyle(
                          color: _getStatusColor(file.uploadStatus),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
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
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _uploadAllFiles,
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
      child: _isPickingFiles
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add, color: Colors.white),
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
            backgroundColor: const Color(0xFF2C2C2E),
            title: const Text(
              'Large Upload',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'You are about to upload ${FileManagementService.formatFileSize(totalSize)} of data. This may take a while and use significant bandwidth. Continue?',
              style: TextStyle(color: Colors.grey[400]),
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
