// RecentsScreen.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserFiles();
  }

  Future<void> _loadUserFiles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Please connect to the internet');
      }

      final response = await FileManagementService.getUserFiles(
        limit: 100,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _userFiles = response.files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('internet')
              ? 'No Internet Connection'
              : 'Failed to load files';
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
    if (result != null &&
        (result == true || result == 'deleted' || result == 'modified')) {
      await _loadUserFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadUserFiles,
        color: const Color(0xFF007AFF),
        backgroundColor: Colors.grey[100],
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          pinned: true,
          floating: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Your Files',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black87,
            ),
          ),
          actions: [_buildViewToggle(), const SizedBox(width: 16)],
        ),
        SliverToBoxAdapter(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_userFiles.isEmpty) {
      return _buildEmptyState();
    }
    return AnimationLimiter(
      child: _isGridView ? _buildFilesGrid() : _buildFilesList(),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildToggleButton(Icons.grid_view_rounded, true),
          _buildToggleButton(Icons.list_alt_rounded, false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(IconData icon, bool isGridViewSelected) {
    final bool isActive = _isGridView == isGridViewSelected;
    return GestureDetector(
      onTap: () => setState(() => _isGridView = isGridViewSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF007AFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[100]!,
        highlightColor: Colors.grey[200]!,
        child: _isGridView
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: 8,
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                itemBuilder: (_, __) => Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _errorMessage!.contains('internet')
                ? Icons.wifi_off
                : Icons.error_outline,
            color: Colors.orange[400],
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pull down to try again.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF007AFF),
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your storage is empty',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Go to the Uploads tab to add your first file.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _userFiles.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 375),
          columnCount: 2,
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _buildFileCardGrid(_userFiles[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _userFiles.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildFileCardList(_userFiles[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileCardGrid(FileItem file) {
    final fileType = _getFileTypeFromCategory(file.fileCategory);
    final iconColor = _getFileTypeColor(fileType);

    return GestureDetector(
      onTap: () => _openFilePreview(file),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Icon(
                  _getFileTypeIconData(fileType),
                  color: iconColor,
                  size: 48,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.filename,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        file.formattedSize,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (file.isPublic)
                        Icon(Icons.public, color: Colors.green[400], size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                _getFileTypeIconData(fileType),
                color: iconColor,
                size: 28,
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
                      color: Colors.black87,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '${file.formattedSize} • ${file.formattedUploadTime}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (file.isPublic)
                  Icon(Icons.public, color: Colors.green[400], size: 16),
                const SizedBox(height: 4),
                if (file.downloadCount > 0)
                  Text(
                    '${file.downloadCount} ↓',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
      case FileType.document:
        return const Color(0xFF007AFF);
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIconData(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return Icons.image_rounded;
      case FileType.video:
        return Icons.videocam_rounded;
      case FileType.audio:
        return Icons.music_note_rounded;
      case FileType.document:
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

enum FileType {
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
