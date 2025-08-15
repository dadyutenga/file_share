import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/file_management_service.dart';
import '../models/FileModels.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserStats? _userStats;
  // Key to reset animations on refresh
  Key _animationKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Please connect to the internet');
      }

      final response = await FileManagementService.getUserFiles(
        limit: 1,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _userStats = response.userStats;
          _isLoading = false;
          // Change the key to re-trigger animations
          _animationKey = UniqueKey();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('internet')
              ? 'No Internet Connection'
              : 'Failed to load storage info';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: RefreshIndicator(
        onRefresh: _loadUserStats,
        color: const Color(0xFF007AFF),
        backgroundColor: const Color(0xFF2C2C2E),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF007AFF)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_userStats == null) {
      return const Center(
        child: Text('No data available.', style: TextStyle(color: Colors.grey)),
      );
    }

    // The main animated content
    return AnimationLimiter(
      key: _animationKey,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildStorageGaugeCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back,',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          _userStats?.username ?? 'User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStorageGaugeCard() {
    final stats = _userStats!;
    final percentage = stats.storagePercentage;
    final color = percentage > 80
        ? Colors.redAccent
        : percentage > 60
        ? Colors.orangeAccent
        : const Color(0xFF007AFF);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 180,
                  endAngle: 0,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.2,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Colors.grey[800],
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: percentage,
                      cornerStyle: CornerStyle.bothCurve,
                      width: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: SweepGradient(
                        colors: <Color>[color.withOpacity(0.8), color],
                        stops: const <double>[0.25, 0.75],
                      ),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      positionFactor: 0.1,
                      angle: 90,
                      widget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedCounter(
                            end: percentage,
                            duration: const Duration(milliseconds: 1200),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            suffix: '%',
                          ),
                          const Text(
                            'Storage Used',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStorageText('Used', stats.formattedStorageUsed),
              _buildStorageText(
                'Available',
                FileManagementService.formatFileSize(stats.storageAvailable),
              ),
              _buildStorageText('Total', stats.formattedStorageLimit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _userStats!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0, // Adjusted for better spacing, making cards square
      children: [
        _buildStatCard(
          'Total Files',
          stats.totalFiles.toDouble(),
          Icons.insert_drive_file,
          const Color(0xFF007AFF),
        ),
        _buildStatCard(
          'Total Downloads',
          stats.totalDownloads.toDouble(),
          Icons.file_download_done,
          Colors.green,
        ),
        _buildDailyDownloadCard(stats),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedCounter(
                end: value,
                duration: const Duration(milliseconds: 1000),
                style: const TextStyle(
                  color: Colors.white,
                  // Adjusted font size to prevent overflow
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                // Ensure text does not wrap
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDownloadCard(UserStats stats) {
    final percentage = stats.dailyDownloadPercentage;
    final color = percentage > 80
        ? Colors.redAccent
        : percentage > 60
        ? Colors.orangeAccent
        : Colors.tealAccent;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Removed MainAxisAlignment.spaceBetween to prevent overflow
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.speed, color: color, size: 20),
          ),
          const Spacer(), // Added a Spacer to push content to the bottom flexibly
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FileManagementService.formatFileSize(stats.dailyDownloadsUsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily Usage',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percentage / 100),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pull down to refresh the screen.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for animating numbers
class _AnimatedCounter extends StatelessWidget {
  final double end;
  final Duration duration;
  final TextStyle style;
  final String suffix;

  const _AnimatedCounter({
    required this.end,
    required this.duration,
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: end),
      duration: duration,
      builder: (context, value, child) {
        final isDecimal = value % 1 != 0;
        final text = isDecimal
            ? value.toStringAsFixed(1)
            : value.toInt().toString();
        return Text('$text$suffix', style: style);
      },
    );
  }
}
