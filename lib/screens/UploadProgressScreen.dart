import 'package:flutter/material.dart';
import 'dart:async';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';
import 'UploadsScreen.dart';

class UploadProgressScreen extends StatefulWidget {
  final List<SelectedFile> files;

  const UploadProgressScreen({super.key, required this.files});

  @override
  State<UploadProgressScreen> createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  int _currentFileIndex = 0;
  double _overallProgress = 0.0;
  bool _isUploading = true;
  bool _isCancelled = false;
  String _currentFileName = '';
  String _uploadSpeed = '';
  String _timeRemaining = '';

  Timer? _speedTimer;
  int _bytesUploaded = 0;
  int _lastBytesUploaded = 0;
  DateTime _uploadStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isCancelled) {
            _startUpload();
            _startSpeedCalculation();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _isCancelled = true;
    super.dispose();
  }

  void _startSpeedCalculation() {
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isCancelled) {
        timer.cancel();
        return;
      }

      if (_isUploading) {
        final speed = (_bytesUploaded - _lastBytesUploaded);
        _lastBytesUploaded = _bytesUploaded;

        if (mounted && speed >= 0) {
          setState(() {
            _uploadSpeed = '${FileManagementService.formatFileSize(speed)}/s';

            final totalSize = widget.files.fold<int>(
              0,
              (sum, file) => sum + file.size,
            );
            final remainingBytes = totalSize - _bytesUploaded;
            if (speed > 0) {
              final secondsRemaining = remainingBytes / speed;
              _timeRemaining = _formatTimeRemaining(secondsRemaining.round());
            }
          });
        }
      }
    });
  }

  String _formatTimeRemaining(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) return '${(seconds / 60).round()} minutes';
    return '${(seconds / 3600).round()} hours';
  }

  Future<void> _startUpload() async {
    if (!mounted || _isCancelled) return;

    try {
      for (int i = 0; i < widget.files.length; i++) {
        if (_isCancelled || !mounted) break;

        final file = widget.files[i];

        if (mounted) {
          setState(() {
            _currentFileIndex = i;
            _currentFileName = file.name;
            file.uploadStatus = UploadStatus.uploading;
          });
        }

        try {
          print('Starting upload for file: ${file.name}');

          final response = await FileManagementService.uploadFile(
            file.file,
            ttl: 0,
            isPublic: false,
            onProgress: (progress) {
              if (!_isCancelled && mounted) {
                setState(() {
                  file.progress = progress;

                  // Calculate overall progress
                  double totalProgress = 0.0;
                  for (int j = 0; j < widget.files.length; j++) {
                    if (j < i) {
                      totalProgress += 1.0;
                    } else if (j == i) {
                      totalProgress += progress;
                    }
                  }
                  _overallProgress = totalProgress / widget.files.length;

                  // Update bytes uploaded
                  final completedBytes = widget.files
                      .take(i)
                      .fold<int>(0, (sum, f) => sum + f.size);
                  _bytesUploaded =
                      completedBytes + (file.size * progress).round();
                });
              }
            },
          );

          print(
            'Upload completed for file: ${file.name}, ID: ${response.fileId}',
          );

          if (!_isCancelled && mounted) {
            setState(() {
              file.uploadStatus = UploadStatus.completed;
              file.progress = 1.0;
              file.uploadId = response.fileId;
            });
          }

          // Small delay between uploads
          if (!_isCancelled && mounted && i < widget.files.length - 1) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (e) {
          print('Upload error for ${file.name}: $e');

          if (!_isCancelled && mounted) {
            setState(() {
              file.uploadStatus = UploadStatus.failed;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ${file.name}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      // Upload completed
      if (!_isCancelled && mounted) {
        setState(() {
          _isUploading = false;
          _overallProgress = 1.0;
        });

        final completedCount = widget.files
            .where((f) => f.uploadStatus == UploadStatus.completed)
            .length;

        if (completedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded $completedCount files'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Auto navigate back after 2 seconds
        Timer(const Duration(seconds: 2), () {
          if (mounted && !_isCancelled) {
            _navigateBack();
          }
        });
      }
    } catch (e) {
      print('Critical upload error: $e');

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _cancelUpload() {
    if (mounted) {
      setState(() {
        _isCancelled = true;
        _isUploading = false;
      });

      for (var file in widget.files) {
        if (file.uploadStatus == UploadStatus.uploading ||
            file.uploadStatus == UploadStatus.pending ||
            file.uploadStatus == UploadStatus.processing) {
          file.uploadStatus =
              UploadStatus.cancelled; // Use cancelled instead of failed
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload cancelled'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvoked: (didPop) {
        if (!didPop && _isUploading) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () {
          if (_isUploading) {
            _showCancelDialog();
          } else {
            _navigateBack();
          }
        },
      ),
      title: const Text(
        'Uploading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildCurrentFileInfo(),
          const SizedBox(height: 40),
          _buildProgressSection(),
          const SizedBox(height: 40),
          _buildStatsSection(),
          const Spacer(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildCurrentFileInfo() {
    if (widget.files.isEmpty) return const SizedBox.shrink();

    final currentFile = _currentFileIndex < widget.files.length
        ? widget.files[_currentFileIndex]
        : widget.files.last;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getFileTypeColor(currentFile.fileType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileTypeIcon(currentFile.fileType),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentFileName.isNotEmpty
                      ? _currentFileName
                      : currentFile.name,
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
                  FileManagementService.formatFileSize(currentFile.size),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_overallProgress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_uploadSpeed.isNotEmpty)
              Text(
                _uploadSpeed,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _overallProgress,
            backgroundColor: const Color(0xFF3A3A3C),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            minHeight: 8,
          ),
        ),
        if (_timeRemaining.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Estimated time remaining: $_timeRemaining',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection() {
    final completedFiles = widget.files
        .where((f) => f.uploadStatus == UploadStatus.completed)
        .length;
    final failedFiles = widget.files
        .where((f) => f.uploadStatus == UploadStatus.failed)
        .length;
    final cancelledFiles = widget.files
        .where((f) => f.uploadStatus == UploadStatus.cancelled)
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Completed', '$completedFiles', Colors.green),
        _buildStatItem('Total', '${widget.files.length}', Colors.blue),
        if (failedFiles > 0)
          _buildStatItem('Failed', '$failedFiles', Colors.red),
        if (cancelledFiles > 0)
          _buildStatItem('Cancelled', '$cancelledFiles', Colors.grey),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        if (_isUploading) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showCancelDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Cancel Upload',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel the upload? All progress will be lost.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue Upload',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelUpload();
            },
            child: const Text(
              'Cancel Upload',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
}
