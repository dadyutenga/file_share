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
        child: SingleChildScrollView(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disk Usage',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '38.4 MB / 1 GB',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    LinearProgressIndicator(
                      value: 0.384, // 38.4%
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30.0),

              // Recent Files section
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Handle list view
                        },
                        icon: Icon(
                          Icons.list,
                          color: Colors.grey[400],
                          size: 20.0,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Handle grid view
                        },
                        icon: const Icon(
                          Icons.grid_view,
                          color: Color(0xFF007AFF),
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // File Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _buildFileCard(index);
                },
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

  Widget _buildFileCard(int index) {
    final List<Map<String, dynamic>> files = [
      {
        'name': 'Project_Proposal.pdf',
        'size': '1.2 MB',
        'icon': Icons.description,
        'color': const Color(0xFF4A90E2),
      },
      {
        'name': 'Vacation_Photo.jpg',
        'size': '4.8 MB',
        'icon': Icons.image,
        'color': const Color(0xFF50C878),
      },
      {
        'name': 'Marketing_Video.mp4',
        'size': '25.3 MB',
        'icon': Icons.videocam,
        'color': const Color(0xFFB19CD9),
      },
      {
        'name': 'Podcast_Episode.mp3',
        'size': '21 MB',
        'icon': Icons.music_note,
        'color': const Color(0xFFFFE135),
      },
    ];

    final file = files[index];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File icon
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: file['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(file['icon'], color: file['color'], size: 24.0),
            ),

            const Spacer(),

            // File info
            Text(
              file['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              file['size'],
              style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
}
