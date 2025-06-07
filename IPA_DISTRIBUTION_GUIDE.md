# IPA Distribution Guide (Without TestFlight)

## Method 1: Development Build + AltStore (Recommended)

### For You (Creator):

#### Step 1: Create Development Build
```bash
# Clean and prepare
flutter clean
flutter pub get

# Build for iOS without code signing
flutter build ios --release --no-codesign
```

#### Step 2: Create IPA manually
```bash
# Navigate to build directory
cd build/ios/iphoneos/

# Create Payload directory
mkdir Payload

# Copy app to Payload
cp -r Runner.app Payload/

# Create IPA
zip -r RoomPlanApp.ipa Payload

# Clean up
rm -rf Payload
```

#### Step 3: Share the IPA
Upload to any file sharing service:
- Google Drive
- Dropbox
- WeTransfer
- Diawi.com (specialized for app sharing)

### For Your Friend (Installer):

#### Step 1: Install AltStore
1. Download AltStore from [altstore.io](https://altstore.io)
2. Follow installation instructions for their OS
3. Install AltStore on their iPhone via AltServer on computer

#### Step 2: Install Your App
1. Download your IPA file
2. Open AltStore on iPhone
3. Tap "+" and select your IPA
4. App will install and work for 7 days

## Method 2: Using Diawi (Easiest)

### Step 1: Create IPA (same as above)

### Step 2: Upload to Diawi
1. Go to [diawi.com](https://diawi.com)
2. Upload your IPA file
3. Fill in details:
   - Title: "RoomPlan Scanner"
   - Password: (optional)
   - Comment: "Requires iPhone 12 Pro+ with LiDAR"
4. Get shareable link

### Step 3: Share with Friend
Send them:
1. The Diawi link
2. Instructions below

## Method 3: Sideloading with Xcode (If they have Mac)

If your friend has a Mac with Xcode:

### Step 1: Share Project
```bash
# Create archive of your project
tar -czf roomplan_project.tar.gz .

# Share via any file service
```

### Step 2: Friend's Instructions
1. Extract project
2. Connect iPhone via USB
3. Open `ios/Runner.xcworkspace` in Xcode
4. Add their Apple ID to Xcode
5. Change Bundle ID to something unique
6. Select their device and press Run

## Installation Instructions for Your Friend

Send them this:

```
📱 How to Install RoomPlan Scanner

⚠️ REQUIREMENTS:
- iPhone 12 Pro or later (with LiDAR)
- iOS 16.0+

🔧 INSTALLATION OPTIONS:

Option A - AltStore (Recommended):
1. Install AltStore from altstore.io
2. Download the IPA I sent you
3. Open AltStore → Tap "+" → Select the IPA
4. App installs and works for 7 days

Option B - Diawi Link:
1. Open the link I sent on your iPhone
2. Tap "Install"
3. Go to Settings → General → Device Management
4. Trust the developer profile
5. App should appear on home screen

Option C - If you have Mac with Xcode:
1. Download project archive I sent
2. Connect iPhone via USB
3. Open in Xcode and run

⚠️ IMPORTANT NOTES:
- App expires after 7 days (you'll need to reinstall)
- You may need to trust the developer in Settings
- If installation fails, try restarting iPhone

🚫 TROUBLESHOOTING:
- "Unable to install": Check iOS version (need 16.0+)
- "Untrusted developer": Go to Settings → General → Device Management
- App crashes: Make sure you have iPhone 12 Pro+ with LiDAR

🎯 TESTING:
1. Open app
2. Should show "RoomPlan is supported" if your device is compatible
3. Tap "Start Room Scan" to test LiDAR functionality
4. Move around room slowly to scan
5. Test save/load features

📝 Send me feedback on any issues!
```

## Automated Build Script

Let me create a script to automate IPA creation: 