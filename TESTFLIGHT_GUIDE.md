# TestFlight Distribution Guide for RoomPlan Flutter App

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Sign up at [developer.apple.com](https://developer.apple.com)
   - Complete enrollment process

2. **Compatible Test Device**
   - iPhone 12 Pro or later (with LiDAR)
   - iPad Pro with LiDAR sensor
   - iOS 16.0 or later

## Step 1: Setup in Xcode

### 1.1 Open the project in Xcode:
```bash
open ios/Runner.xcworkspace
```

### 1.2 Configure Signing & Capabilities:
1. Select **Runner** project in navigator
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. **Sign in with your Apple ID** if not already signed in:
   - Xcode → Preferences → Accounts → Add Apple ID
5. Set **Team** to your developer team
6. Ensure **Bundle Identifier** is unique (change `com.example.roomplanFlutterPoc` to something like `com.yourname.roomplanapp`)

### 1.3 Update Bundle Identifier:
```bash
# Edit ios/Runner/Info.plist if needed
# CFBundleIdentifier should match your chosen bundle ID
```

## Step 2: Create App Record in App Store Connect

### 2.1 Go to App Store Connect:
1. Visit [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID
3. Click **My Apps**

### 2.2 Create New App:
1. Click **+** button → **New App**
2. Fill in details:
   - **Platform**: iOS
   - **Name**: RoomPlan Scanner (or your preferred name)
   - **Primary Language**: English
   - **Bundle ID**: Select the one you configured in Xcode
   - **SKU**: Any unique identifier (e.g., roomplan-scanner-001)

## Step 3: Archive and Upload

### 3.1 Create Archive in Xcode:
1. In Xcode, select **Any iOS Device** (not simulator)
2. Go to **Product** → **Archive**
3. Wait for the archive process to complete
4. The **Organizer** window will open

### 3.2 Distribute to App Store Connect:
1. In Organizer, select your archive
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Click **Next** → **Upload**
5. Follow the prompts to upload

## Step 4: Setup TestFlight

### 4.1 Wait for Processing:
- After upload, wait 5-10 minutes for App Store Connect to process your build
- You'll receive an email when processing is complete

### 4.2 Configure TestFlight:
1. In App Store Connect, go to your app
2. Click **TestFlight** tab
3. Select your build under **iOS**
4. Click **Manage** next to External Testing
5. Add **Test Information**:
   - **What to Test**: "Test RoomPlan functionality - scan rooms using LiDAR sensor"
   - **App Description**: Brief description of the app
   - **Feedback Email**: Your email address
   - **Marketing URL**: (optional)
   - **Privacy Policy URL**: (optional for TestFlight)

### 4.3 Submit for Beta App Review:
1. Click **Submit for Review**
2. Apple will review your app (usually takes 24-48 hours)

## Step 5: Invite Testers

### 5.1 Add External Testers:
1. Go to **TestFlight** → **External Testing**
2. Click **+** next to Testers
3. Enter tester email addresses
4. Add testers to your build
5. Click **Send Invites**

### 5.2 Tester Instructions:
Send these instructions to your testers:

```
📱 How to Test the RoomPlan App:

1. Install TestFlight from the App Store
2. Check your email for the TestFlight invitation
3. Tap the invitation link or redeem the code in TestFlight
4. Download and install the app

⚠️ IMPORTANT: This app requires:
- iPhone 12 Pro or later (with LiDAR sensor)
- iPad Pro with LiDAR sensor
- iOS 16.0 or later

🎯 What to Test:
1. Open the app
2. Check if "RoomPlan is supported" appears
3. Tap "Start Room Scan"
4. Move around a room slowly to scan
5. Tap "Done" when finished
6. Verify scan results are displayed
7. Test saving/loading scans
8. Try deleting saved scans

📝 Please report any issues or feedback!
```

## Alternative: Quick Build Script

I've created a build script you can run:

```bash
./build_for_testing.sh
```

This will prepare the build, then you'll need to:
1. Open the workspace in Xcode
2. Archive and upload to App Store Connect

## Troubleshooting

### Code Signing Issues:
- Make sure you're signed in to Xcode with your Apple ID
- Verify your Apple Developer account is active
- Check that Bundle ID is unique and registered

### Build Failures:
- Run `flutter clean && flutter pub get`
- Ensure Xcode is up to date
- Check that iOS deployment target is set to 16.0+

### TestFlight Issues:
- External testing requires Beta App Review (24-48 hours)
- Internal testing (up to 100 users) is immediate if they're on your dev team
- Builds expire after 90 days

## Testing Checklist for Testers

- [ ] App launches successfully
- [ ] Shows "RoomPlan is supported" on compatible devices
- [ ] Shows "not supported" message on incompatible devices/simulator
- [ ] Room scanning works with LiDAR
- [ ] Scan results display correctly
- [ ] Can save scan data
- [ ] Can load previously saved scans
- [ ] Can delete saved scans
- [ ] UI is responsive and intuitive

## Cost Breakdown

- **Apple Developer Account**: $99/year
- **TestFlight**: Free (included with developer account)
- **Distribution**: Free for testing (up to 10,000 external testers)

Ready to start? Run the build script and follow the Xcode steps above! 