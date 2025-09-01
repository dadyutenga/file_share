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
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: _loadUserStats,
        color: const Color(0xFF007AFF),
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        displacement: 60.0,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFF007AFF),
                strokeWidth: 3.0,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your dashboard...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_userStats == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, color: Colors.grey[400], size: 64),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      key: _animationKey,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            curve: Curves.easeOutCubic,
            child: FadeInAnimation(curve: Curves.easeOut, child: widget),
          ),
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 20),
            _buildStorageGaugeCard(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF007AFF).withOpacity(0.05),
            const Color(0xFF5856D6).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF007AFF).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userStats?.username ?? 'User',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF007AFF),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageGaugeCard() {
    final stats = _userStats!;
    final percentage = stats.storagePercentage;
    final color = percentage > 80
        ? const Color(0xFFFF3B30)
        : percentage > 60
        ? const Color(0xFFFF9500)
        : const Color(0xFF007AFF);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
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
                    thickness: 0.15,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Colors.grey[100]!,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: percentage,
                      cornerStyle: CornerStyle.bothCurve,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: SweepGradient(
                        colors: <Color>[
                          color.withOpacity(0.3),
                          color.withOpacity(0.8),
                          color,
                        ],
                        stops: const <double>[0.0, 0.5, 1.0],
                      ),
                      enableAnimation: true,
                      animationDuration: 1500,
                      animationType: AnimationType.easeOutBack,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      positionFactor: 0.1,
                      angle: 90,
                      widget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Fix: Prevent Column overflow
                        children: [
                          _AnimatedCounter(
                            end: percentage,
                            duration: const Duration(milliseconds: 1500),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: -1,
                            ),
                            suffix: '%',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Storage Used',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStorageText('Used', stats.formattedStorageUsed, color),
                Container(width: 1, height: 32, color: Colors.grey[200]),
                _buildStorageText(
                  'Available',
                  FileManagementService.formatFileSize(stats.storageAvailable),
                  const Color(0xFF34C759),
                ),
                Container(width: 1, height: 32, color: Colors.grey[200]),
                _buildStorageText(
                  'Total',
                  stats.formattedStorageLimit,
                  Colors.grey[600]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageText(String label, String value, Color accentColor) {
    return Flexible( // Fix: Use Flexible to prevent overflow
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fix: Prevent Column overflow
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center, // Fix: Center text to prevent overflow
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: accentColor,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center, // Fix: Center text to prevent overflow
            maxLines: 1, // Fix: Prevent text overflow
            overflow: TextOverflow.ellipsis, // Fix: Handle text overflow
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _userStats!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.6, // Fix: Increased from 2.4 to give even more height
      children: [
        _buildStatCard(
          'Total Files',
          stats.totalFiles.toDouble(),
          Icons.folder_rounded,
          const Color(0xFF007AFF),
        ),
        _buildStatCard(
          'Total Downloads',
          stats.totalDownloads.toDouble(),
          Icons.cloud_download_rounded,
          const Color(0xFF34C759),
        ),
        _buildDailyDownloadCard(stats),
        _buildQuickActionCard(),
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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0), // Add padding to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible( // Wrap AnimatedCounter in Flexible
                    child: _AnimatedCounter(
                      end: value,
                      duration: const Duration(milliseconds: 1200),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18, // Slightly reduced font size
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible( // Wrap title text in Flexible
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10, // Slightly reduced font size
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDownloadCard(UserStats stats) {
    final percentage = stats.dailyDownloadPercentage;
    final color = percentage > 80
        ? const Color(0xFFFF3B30)
        : percentage > 60
        ? const Color(0xFFFF9500)
        : const Color(0xFF5AC8FA);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insights_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0), // Add padding to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible( // Wrap file size text in Flexible
                    child: Text(
                      FileManagementService.formatFileSize(
                        stats.dailyDownloadsUsed,
                      ),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14, // Slightly reduced font size
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible( // Wrap title text in Flexible
                    child: Text(
                      'Daily Usage',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10, // Slightly reduced font size
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Container( // Keep progress bar as is, but reduce spacing above
                    height: 3, // Slightly reduced height
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentage / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[100],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.6), color],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF5856D6).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5856D6).withOpacity(0.1),
                  const Color(0xFF5856D6).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF5856D6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0), // Add padding to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible( // Wrap Upload text in Flexible
                    child: Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14, // Slightly reduced font size
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible( // Wrap subtitle text in Flexible
                    child: Text(
                      'Quick Action',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10, // Slightly reduced font size
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView( // Fix: Add scrollability to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _errorMessage!.contains('internet')
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    color: const Color(0xFFFF9500),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pull down to refresh the screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadUserStats,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFF007AFF).withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final isDecimal = value % 1 != 0 && end < 100;
        final text = isDecimal
            ? value.toStringAsFixed(1)
            : value.toInt().toString();
        return Text('$text$suffix', style: style);
      },
    );
  }
}