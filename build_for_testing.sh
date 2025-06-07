#!/bin/bash

echo "🏗️  Building RoomPlan Flutter App for Testing..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for iOS release
echo "📱 Building iOS release..."
flutter build ios --release --no-codesign

echo "📦 Creating archive..."
cd ios

# Create archive without code signing for now
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath build/Runner.xcarchive \
           archive \
           CODE_SIGNING_ALLOWED=NO

echo "✅ Build completed!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Select 'Any iOS Device' as target"
echo "3. Go to Product → Archive"
echo "4. Choose distribution method:"
echo "   - TestFlight: For external beta testing"
echo "   - Ad Hoc: For specific devices"
echo "   - Development: For registered devices"
echo ""
echo "💡 Note: You'll need an Apple Developer account to sign and distribute the app." 