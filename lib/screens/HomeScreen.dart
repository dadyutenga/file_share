import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Set status bar style for this screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FileShare',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Handle profile/settings
            },
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 28.0,
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Padding(
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

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Upload File',
                      subtitle: 'Share your files',
                      color: const Color(0xFF007AFF),
                      onTap: () {
                        // Handle file upload
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.cloud_download_outlined,
                      title: 'Download',
                      subtitle: 'Get shared files',
                      color: const Color(0xFF34C759),
                      onTap: () {
                        // Handle file download
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30.0),

              // Recent files section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Files',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle see all
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // Recent files list
              Expanded(
                child: ListView.builder(
                  itemCount: 5, // Placeholder count
                  itemBuilder: (context, index) {
                    return _buildFileItem(
                      fileName: 'Document_${index + 1}.pdf',
                      fileSize: '${(index + 1) * 2}.5 MB',
                      uploadDate: '${index + 1} days ago',
                      fileType: 'PDF',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle quick upload
        },
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, color: Colors.white, size: 28.0),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32.0),
            const SizedBox(height: 12.0),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem({
    required String fileName,
    required String fileSize,
    required String uploadDate,
    required String fileType,
  }) {
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
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF007AFF),
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
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$fileSize • $uploadDate',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            onPressed: () {
              // Handle file options
            },
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20.0),
          ),
        ],
      ),
    );
  }
}
