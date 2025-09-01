#!/bin/bash

# FileShare App Icon Generation Script
# This script helps you generate app icons from your source image

echo "🚀 FileShare App Icon Generation"
echo "================================="

# Check if the source icon exists
if [ ! -f "assets/icon/app_icon.png" ]; then
    echo "❌ Error: assets/icon/app_icon.png not found!"
    echo "Please save your blue cloud upload icon as 'app_icon.png' in the assets/icon/ folder"
    echo "Make sure it's a high-resolution PNG (1024x1024 or higher) for best results"
    exit 1
fi

echo "✅ Source icon found: assets/icon/app_icon.png"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate icons
echo "🎨 Generating app icons..."
flutter pub run flutter_launcher_icons:main

# Build for testing
echo "🔨 Building APK for testing..."
flutter build apk --debug

echo "✅ Done! Your new app icon has been generated."
echo ""
echo "📱 To test your new icon:"
echo "   1. Install the generated APK on your device"
echo "   2. Look for the FileShare app with your new blue cloud icon"
echo ""
echo "🔄 If you need to update the icon:"
echo "   1. Replace assets/icon/app_icon.png with your new image"
echo "   2. Run this script again"
