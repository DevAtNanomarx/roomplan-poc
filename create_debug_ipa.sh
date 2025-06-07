#!/bin/bash

echo "🔍 Creating DEBUG IPA for Testing..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Build the iOS app in PROFILE mode (includes debug info but optimized)
echo -e "${BLUE}📱 Building iOS app in PROFILE mode...${NC}"
flutter build ios --profile --no-codesign

# Check if build was successful
if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
    echo -e "${RED}❌ Build failed. Check the error messages above.${NC}"
    exit 1
fi

# Navigate to build directory
cd build/ios/iphoneos/

# Create IPA
echo -e "${BLUE}📦 Creating DEBUG IPA file...${NC}"

# Remove existing IPA if it exists
rm -f RoomPlanApp_Debug.ipa

# Create Payload directory
mkdir -p Payload

# Copy the app bundle to Payload
cp -r Runner.app Payload/

# Create the IPA file
zip -r RoomPlanApp_Debug.ipa Payload > /dev/null

# Clean up Payload directory
rm -rf Payload

# Check if IPA was created successfully
if [ -f "RoomPlanApp_Debug.ipa" ]; then
    # Get file size
    IPA_SIZE=$(du -h RoomPlanApp_Debug.ipa | cut -f1)
    
    echo -e "${GREEN}✅ DEBUG IPA created successfully!${NC}"
    echo -e "${GREEN}📁 Location: $(pwd)/RoomPlanApp_Debug.ipa${NC}"
    echo -e "${GREEN}📏 Size: $IPA_SIZE${NC}"
    echo ""
    echo -e "${YELLOW}🔍 DEBUG Features Included:${NC}"
    echo "   ✅ Console logging (use Xcode Console or device logs)"
    echo "   ✅ Debug symbols for crash analysis"
    echo "   ✅ Performance profiling capabilities"
    echo "   ✅ Better error messages"
    echo ""
    echo -e "${BLUE}📱 To view logs after installation:${NC}"
    echo "   • Connect device to Mac"
    echo "   • Open Xcode → Window → Devices and Simulators"
    echo "   • Select device → Open Console"
    echo "   • Filter by 'Runner' to see your app logs"
    echo ""
    echo -e "${YELLOW}⚠️  Note: Debug builds are larger and slightly slower than release builds${NC}"
    
    # Open the directory in Finder (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open .
    fi
    
else
    echo -e "${RED}❌ Failed to create DEBUG IPA file.${NC}"
    exit 1
fi

# Go back to project root
cd ../../../ 