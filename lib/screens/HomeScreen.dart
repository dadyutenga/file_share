import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserStats? _userStats;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _errorMessage = 'Please connect to the internet';
          _isLoading = false;
        });
        return;
      }

      final response = await FileManagementService.getUserFiles(
        limit: 1,
        offset: 0,
      );

      setState(() {
        _userStats = response.userStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('Network') ||
            e.toString().contains('Connection')) {
          _errorMessage = 'Please connect to the internet';
        } else {
          _errorMessage = 'Failed to load storage info: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUserStats,
      color: const Color(0xFF007AFF),
      backgroundColor: const Color(0xFF2C2C2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStorageCard(),
            const SizedBox(height: 20.0),
            _buildDownloadLimitsCard(),
            const SizedBox(height: 20.0),
            _buildQuickStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    if (_isLoading) {
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

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
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
                  : 'Failed to load storage info',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loadUserStats,
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

    if (_userStats == null) {
      return const SizedBox.shrink();
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
                'Storage Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_userStats!.totalFiles} files',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Used Storage',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userStats!.formattedStorageUsed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total Storage',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userStats!.formattedStorageLimit,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Available',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FileManagementService.formatFileSize(
                        _userStats!.storageAvailable,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          LinearProgressIndicator(
            value: _userStats!.storagePercentage / 100,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              _userStats!.storagePercentage > 80
                  ? Colors.red
                  : _userStats!.storagePercentage > 60
                  ? Colors.orange
                  : const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_userStats!.storagePercentage.toStringAsFixed(1)}% used',
                style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
              ),
              if (_userStats!.username != null)
                Text(
                  '@${_userStats!.username}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadLimitsCard() {
    if (_userStats == null) return const SizedBox.shrink();

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
            children: [
              Icon(Icons.download, color: Colors.blue[400], size: 20.0),
              const SizedBox(width: 8.0),
              const Text(
                'Daily Download Limits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloads Used',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FileManagementService.formatFileSize(
                        _userStats!.dailyDownloadsUsed,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Daily Limit',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userStats!.formattedDownloadLimit,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          LinearProgressIndicator(
            value: _userStats!.dailyDownloadPercentage / 100,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              _userStats!.dailyDownloadPercentage > 80
                  ? Colors.red
                  : _userStats!.dailyDownloadPercentage > 60
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '${_userStats!.dailyDownloadPercentage.toStringAsFixed(1)}% of daily limit used',
            style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_userStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Files',
                '${_userStats!.totalFiles}',
                Icons.insert_drive_file,
                const Color(0xFF007AFF),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildStatCard(
                'Total Downloads',
                '${_userStats!.totalDownloads}',
                Icons.download,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'User ID',
                '#${_userStats!.userId}',
                Icons.person,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildStatCard(
                'Storage Used',
                '${_userStats!.storagePercentage.toStringAsFixed(1)}%',
                Icons.storage,
                _userStats!.storagePercentage > 80
                    ? Colors.red
                    : _userStats!.storagePercentage > 60
                    ? Colors.orange
                    : const Color(0xFF007AFF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20.0),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
          ),
        ],
      ),
    );
  }
}
