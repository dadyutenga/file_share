import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      style: TextStyle(color: Colors.grey[400], fontSize: 14.0),
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

          // Files will be loaded here from backend
          Container(
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
                  'Your files will appear here',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Upload your first file to get started',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
