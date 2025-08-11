import 'package:flutter/material.dart';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isGridView = true;
  List<FileItem> _userFiles = [];
  String? _errorMessage;
  UserStats? _userStats;

  @override
  void initState() {
    super.initState();
    _loadUserFiles();
  }

  Future<void> _loadUserFiles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch user files using correct parameters
      final response = await FileManagementService.getUserFiles(
        limit: 50,
        offset: 0,
      );

      setState(() {
        _userFiles = response.files;
        _userStats = response.userStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load files: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUserFiles,
      color: const Color(0xFF007AFF),
      backgroundColor: const Color(0xFF2C2C2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Welcome back!',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30.0),

            // Disk Usage Card
            _buildDiskUsageCard(),

            const SizedBox(height: 30.0),

            // Files section
            _buildFilesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiskUsageCard() {
    // Use cached stats if available, otherwise show loading
    if (_userStats == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF007AFF)),
            SizedBox(height: 16.0),
            Text(
              'Loading storage info...',
              style: TextStyle(color: Colors.grey, fontSize: 14.0),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Storage Usage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_userStats!.totalFiles} files',
                style: TextStyle(color: Colors.grey[400], fontSize: 14.0),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            '${_userStats!.formattedStorageUsed} / ${_userStats!.formattedStorageLimit}',
            style: TextStyle(color: Colors.grey[400], fontSize: 14.0),
          ),
          const SizedBox(height: 8.0),
          LinearProgressIndicator(
            value: _userStats!.storagePercentage / 100,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              _userStats!.storagePercentage > 80
                  ? Colors.red
                  : const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '${_userStats!.storagePercentage.toStringAsFixed(1)}% used',
            style: TextStyle(color: Colors.grey[500], fontSize: 12.0),
          ),
        ],
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
        // Files header with view toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Files (${_userFiles.length})',
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

        // Files grid/list
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
            'Loading your files...',
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
          Icon(Icons.error_outline, color: Colors.red[400], size: 64.0),
          const SizedBox(height: 16.0),
          Text(
            'Failed to load files',
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
            child: const Text('Retry'),
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
            'Your files will appear here',
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon with status indicators
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
                      Icon(Icons.public, color: Colors.green[400], size: 16.0),
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

            // File info
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
    );
  }

  Widget _buildFileCardList(FileItem file) {
    final fileType = _getFileTypeFromCategory(file.fileCategory);
    final iconColor = _getFileTypeColor(fileType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // File type icon
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

          // File info
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
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12.0),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      file.formattedUploadTime,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status indicators
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
