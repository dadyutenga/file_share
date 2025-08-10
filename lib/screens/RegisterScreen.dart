import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 60.0),
                // Cloud upload icon
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: Color(0xFF007AFF),
                  size: 64.0,
                ),
                const SizedBox(height: 40.0),
                // Create Account title
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                // Subtitle
                Text(
                  'Join FileShare to start sharing files',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48.0),
                // Username field
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    hintText: 'Username',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16.0,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 18.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Password field
                TextField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16.0,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 18.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
                // Register button
                ElevatedButton(
                  onPressed: () {
                    // Handle registration
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                // Login link - Smooth navigation
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey[400], fontSize: 14.0),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login here',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
