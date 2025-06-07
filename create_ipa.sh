#!/bin/bash

echo "🚀 Creating IPA for RoomPlan Flutter App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Build the iOS app without code signing
echo -e "${BLUE}📱 Building iOS app...${NC}"
flutter build ios --release --no-codesign

# Check if build was successful
if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
    echo -e "${RED}❌ Build failed. Check the error messages above.${NC}"
    exit 1
fi

# Navigate to build directory
cd build/ios/iphoneos/

# Create IPA
echo -e "${BLUE}📦 Creating IPA file...${NC}"

# Remove existing IPA if it exists
rm -f RoomPlanApp.ipa

# Create Payload directory
mkdir -p Payload

# Copy the app bundle to Payload
cp -r Runner.app Payload/

# Create the IPA file
zip -r RoomPlanApp.ipa Payload > /dev/null

# Clean up Payload directory
rm -rf Payload

# Check if IPA was created successfully
if [ -f "RoomPlanApp.ipa" ]; then
    # Get file size
    IPA_SIZE=$(du -h RoomPlanApp.ipa | cut -f1)
    
    echo -e "${GREEN}✅ IPA created successfully!${NC}"
    echo -e "${GREEN}📁 Location: $(pwd)/RoomPlanApp.ipa${NC}"
    echo -e "${GREEN}📏 Size: $IPA_SIZE${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Upload RoomPlanApp.ipa to a file sharing service:"
    echo "   • Google Drive"
    echo "   • Dropbox" 
    echo "   • WeTransfer"
    echo "   • Diawi.com (recommended for app sharing)"
    echo ""
    echo "2. Send the download link to your friend along with installation instructions"
    echo ""
    echo -e "${BLUE}💡 Pro tip: Upload to diawi.com for the easiest installation experience!${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Remember: This IPA will only work on:${NC}"
    echo "   • iPhone 12 Pro or later (with LiDAR)"
    echo "   • iPad Pro with LiDAR sensor"
    echo "   • iOS 16.0 or later"
    echo ""
    echo -e "${GREEN}🎉 Your RoomPlan app is ready for testing!${NC}"
    
    # Open the directory in Finder (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open .
    fi
    
else
    echo -e "${RED}❌ Failed to create IPA file.${NC}"
    exit 1
fi

# Go back to project root
cd ../../../ 