import 'package:flutter/material.dart';
import 'dart:async';
import '../services/file_management_service.dart';
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
  double _currentFileProgress = 0.0;
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
    // Use post frame callback to avoid widget lifecycle issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startUpload();
        _startSpeedCalculation();
      }
    });
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _isCancelled = true; // Set cancel flag
    super.dispose();
  }

  void _startSpeedCalculation() {
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isCancelled) {
        timer.cancel();
        return;
      }

      if (_isUploading) {
        final now = DateTime.now();
        final duration = now.difference(_uploadStartTime).inSeconds;

        if (duration > 0) {
          final speed = (_bytesUploaded - _lastBytesUploaded);
          _lastBytesUploaded = _bytesUploaded;

          if (mounted) {
            setState(() {
              _uploadSpeed = '${FileManagementService.formatFileSize(speed)}/s';

              // Calculate time remaining
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

    for (int i = 0; i < widget.files.length; i++) {
      if (_isCancelled || !mounted) break;

      final file = widget.files[i];

      if (mounted) {
        setState(() {
          _currentFileIndex = i;
          _currentFileName = file.name;
          _currentFileProgress = 0.0;
          file.uploadStatus = UploadStatus.uploading;
        });
      }

      try {
        await FileManagementService.uploadFile(
          file.file,
          onProgress: (progress) {
            if (!_isCancelled && mounted) {
              setState(() {
                _currentFileProgress = progress;
                file.progress = progress;

                // Calculate overall progress
                double totalProgress = 0.0;
                for (int j = 0; j < widget.files.length; j++) {
                  if (j < i) {
                    totalProgress += 1.0; // Completed files
                  } else if (j == i) {
                    totalProgress += progress; // Current file
                  }
                }
                _overallProgress = totalProgress / widget.files.length;

                // Update bytes uploaded
                _bytesUploaded =
                    widget.files
                        .take(i)
                        .fold<int>(0, (sum, f) => sum + f.size) +
                    (file.size * progress).round();
              });
            }
          },
        );

        if (!_isCancelled && mounted) {
          setState(() {
            file.uploadStatus = UploadStatus.completed;
            file.progress = 1.0;
          });
        }
      } catch (e) {
        if (!_isCancelled && mounted) {
          setState(() {
            file.uploadStatus = UploadStatus.failed;
          });
        }
      }
    }

    if (!_isCancelled && mounted) {
      setState(() {
        _isUploading = false;
        _overallProgress = 1.0;
      });

      // Auto navigate back after 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted && !_isCancelled) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _cancelUpload() {
    if (mounted) {
      setState(() {
        _isCancelled = true;
        _isUploading = false;
      });
    }

    // Mark remaining files as failed
    for (var file in widget.files) {
      if (file.uploadStatus == UploadStatus.uploading ||
          file.uploadStatus == UploadStatus.pending) {
        file.uploadStatus = UploadStatus.failed;
      }
    }
  }

  void _viewFiles() {
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUploading) {
          _showCancelDialog();
          return false;
        }
        return true;
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
            Navigator.pop(context, true);
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
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 28),
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
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * _overallProgress - 48,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Completed', '$completedFiles', Colors.green),
        _buildStatItem('Total', '${widget.files.length}', Colors.blue),
        if (failedFiles > 0)
          _buildStatItem('Failed', '$failedFiles', Colors.red),
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
              onPressed: _viewFiles,
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
                'View Files',
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
              style: TextStyle(color: Colors.blue),
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
}
