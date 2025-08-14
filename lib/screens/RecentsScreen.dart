// RecentsScreen.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';
import 'PreviewScreen.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isGridView = true;
  List<FileItem> _userFiles = [];
  String? _errorMessage;
  UserStats? _userStats;

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    _loadUserFiles();
  }

  Future<void> _loadUserFiles() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please connect to the internet';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await FileManagementService.getUserFiles(
        limit: 100, // Load more files for recents
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _userFiles = response.files;
          _userStats = response.userStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('Network') ||
              e.toString().contains('Connection')) {
            _errorMessage = 'Please connect to the internet';
          } else {
            _errorMessage = 'Failed to load files: ${e.toString()}';
          }
          _isLoading = false;
        });
      }
    }
  }

  void _openFilePreview(FileItem file) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PreviewScreen(file: file)),
    );

    if (result != null && mounted) {
      if (result == true || result == 'deleted' || result == 'modified') {
        await _loadUserFiles();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: _loadUserFiles,
      color: const Color(0xFF007AFF),
      backgroundColor: const Color(0xFF2C2C2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildFilesSection()],
        ),
      ),
    );
  }

  Widget _buildFilesSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_userFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Files (${_userFiles.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _isGridView = false),
                  icon: Icon(
                    Icons.list,
                    color: !_isGridView
                        ? const Color(0xFF007AFF)
                        : Colors.grey[400],
                    size: 20.0,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isGridView = true),
                  icon: Icon(
                    Icons.grid_view,
                    color: _isGridView
                        ? const Color(0xFF007AFF)
                        : Colors.grey[400],
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        _isGridView ? _buildFilesGrid() : _buildFilesList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF007AFF)),
          SizedBox(height: 16.0),
          Text(
            'Loading files...',
            style: TextStyle(color: Colors.grey, fontSize: 16.0),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Icon(
            _errorMessage!.contains('internet')
                ? Icons.wifi_off
                : Icons.error_outline,
            color: _errorMessage!.contains('internet')
                ? Colors.orange[400]
                : Colors.red[400],
            size: 64.0,
          ),
          const SizedBox(height: 16.0),
          Text(
            _errorMessage!.contains('internet')
                ? 'No Internet Connection'
                : 'Failed to load files',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.grey[500], fontSize: 14.0),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _loadUserFiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
            child: Text(
              _errorMessage!.contains('internet') ? 'Retry' : 'Retry',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_outlined, color: Colors.grey[400], size: 64.0),
          const SizedBox(height: 16.0),
          Text(
            'No files uploaded yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Upload some files to get started',
            style: TextStyle(color: Colors.grey[500], fontSize: 14.0),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: _userFiles.length,
      itemBuilder: (context, index) => _buildFileCardGrid(_userFiles[index]),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userFiles.length,
      itemBuilder: (context, index) => _buildFileCardList(_userFiles[index]),
    );
  }

  Widget _buildFileCardGrid(FileItem file) {
    final fileType = _getFileTypeFromCategory(file.fileCategory);
    final iconColor = _getFileTypeColor(fileType);

    return GestureDetector(
      onTap: () => _openFilePreview(file),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      _getFileTypeIconData(fileType),
                      color: iconColor,
                      size: 24.0,
                    ),
                  ),
                  Column(
                    children: [
                      if (file.isPublic)
                        Icon(
                          Icons.public,
                          color: Colors.green[400],
                          size: 16.0,
                        ),
                      if (file.isExpired)
                        Icon(
                          Icons.access_time,
                          color: Colors.red[400],
                          size: 16.0,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Flexible(
                child: Text(
                  file.filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                file.formattedSize,
                style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
              ),
              const SizedBox(height: 2.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    file.formattedUploadTime,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11.0),
                  ),
                  if (file.downloadCount > 0)
                    Text(
                      '${file.downloadCount} ↓',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11.0),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCardList(FileItem file) {
    final fileType = _getFileTypeFromCategory(file.fileCategory);
    final iconColor = _getFileTypeColor(fileType);

    return GestureDetector(
      onTap: () => _openFilePreview(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                _getFileTypeIconData(fileType),
                color: iconColor,
                size: 24.0,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.filename,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        file.formattedSize,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        file.formattedUploadTime,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (file.isPublic)
                  Icon(Icons.public, color: Colors.green[400], size: 16.0),
                if (file.isExpired)
                  Icon(Icons.access_time, color: Colors.red[400], size: 16.0),
                if (file.downloadCount > 0)
                  Text(
                    '${file.downloadCount} ↓',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10.0),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
}
