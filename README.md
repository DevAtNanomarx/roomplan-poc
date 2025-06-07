# RoomPlan Flutter POC

A Flutter app that integrates with Apple's RoomPlan framework to scan and create 3D models of rooms using LiDAR sensors.

## Features

- **Device Compatibility Check**: Automatically detects if the device supports RoomPlan
- **Cross-Platform Handling**: Gracefully handles Android devices and iOS devices without LiDAR
- **Lossless Data Transfer**: Preserves all RoomPlan data including surfaces, objects, dimensions, and transforms
- **Native iOS Integration**: Uses platform channels to access native RoomPlan APIs
- **User-Friendly Interface**: Clean Flutter UI with scanning progress and results display

## Requirements

### iOS Requirements
- **iOS 16.0 or later** (RoomPlan framework requirement)
- **LiDAR sensor** (iPhone 12 Pro, iPhone 12 Pro Max, iPhone 13 Pro, iPhone 13 Pro Max, iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 Pro, iPhone 15 Pro Max, iPad Pro 11-inch (2nd generation or later), iPad Pro 12.9-inch (4th generation or later))
- **Camera permission** for room scanning

### Development Requirements
- Flutter 3.8.1 or later
- Xcode 14.0 or later
- CocoaPods (for iOS dependency management)

## Setup Instructions

### 1. Install Prerequisites

If you don't have CocoaPods installed:
```bash
sudo gem install cocoapods
```

### 2. Get Flutter Dependencies
```bash
flutter pub get
```

### 3. Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

### 4. Run the App
```bash
# On iOS Simulator (limited functionality - RoomPlan not supported)
flutter run

# On physical iOS device with LiDAR
flutter run --device-id [your-device-id]
```

## Project Structure

### Flutter Side (`lib/main.dart`)
- **Platform Channel Setup**: Communicates with native iOS code
- **Device Support Check**: Verifies RoomPlan compatibility
- **UI Components**: Scan button, progress indicators, results display
- **Error Handling**: Graceful fallbacks for unsupported devices

### iOS Native Code (`ios/Runner/`)
- **AppDelegate.swift**: Platform channel registration
- **RoomPlanHandler.swift**: Core RoomPlan integration
  - Device support checking
  - Room scanning session management
  - Data conversion to JSON
  - Custom scan UI with Done/Cancel buttons

### Key Files
```
lib/
  main.dart                 # Flutter app with RoomPlan integration

ios/Runner/
  AppDelegate.swift         # Platform channel setup
  RoomPlanHandler.swift     # RoomPlan native implementation
  Info.plist               # Camera permission configuration

ios/
  Podfile                  # iOS dependencies and deployment target
```

## Data Structure

The app returns comprehensive room data as JSON with the following structure:

```json
{
  "confidence": "high|medium|low",
  "dimensions": {
    "width": 4.5,
    "height": 2.8,
    "length": 6.2
  },
  "surfaces": [
    {
      "category": "wall|floor|ceiling|door|window|opening",
      "confidence": "high|medium|low",
      "dimensions": {
        "width": 2.0,
        "height": 2.5
      },
      "transform": {
        "translation": { "x": 1.0, "y": 0.0, "z": 2.0 },
        "rotation": { "m00": 1.0, "m01": 0.0, ... }
      }
    }
  ],
  "objects": [
    {
      "category": "sofa|table|chair|bed|...",
      "confidence": "high|medium|low",
      "dimensions": {
        "width": 1.8,
        "height": 0.4,
        "length": 0.9
      },
      "transform": {
        "translation": { "x": 2.0, "y": 0.0, "z": 1.0 },
        "rotation": { "m00": 1.0, "m01": 0.0, ... }
      }
    }
  ]
}
```

## Usage

1. **Launch the app** on a compatible iOS device
2. **Check compatibility** - The app automatically detects RoomPlan support
3. **Start scanning** - Tap "Start Room Scan" to begin
4. **Scan the room** - Move around the room following the on-screen instructions
5. **Complete scan** - Tap "Done" when finished, or "Cancel" to abort
6. **View results** - The app displays detected surfaces, objects, and room dimensions

## Platform Handling

### iOS with LiDAR Support
- Full RoomPlan functionality
- 3D room scanning with surfaces and objects detection
- High-precision measurements and spatial data

### iOS without LiDAR
- Shows "not supported" message
- Graceful error handling
- No crash or unexpected behavior

### Android
- Shows "iOS only" message
- Clean fallback experience
- Explains RoomPlan limitations

## Error Handling

The app handles various scenarios gracefully:

- **Unsupported devices**: Clear messaging about requirements
- **Scan failures**: Error messages with retry options
- **Permission issues**: Helpful camera permission explanations
- **iOS version compatibility**: Version-specific feature checks

## Development Notes

### Platform Channel Communication
- Uses `MethodChannel` for Flutter-to-iOS communication
- JSON serialization for complex data transfer
- Async/await pattern for scan operations

### iOS Integration
- Uses `@available(iOS 16.0, *)` for version compatibility
- Implements `RoomCaptureViewDelegate` for scan lifecycle
- Custom view controller for scan UI

### Data Preservation
- All RoomPlan data is preserved including:
  - 3D transforms and positions
  - Surface and object classifications
  - Confidence levels
  - Precise measurements

## Troubleshooting

### Common Issues

1. **"RoomPlan not supported"**
   - Ensure device has LiDAR sensor
   - Check iOS version (16.0+ required)
   - Verify camera permissions

2. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Ensure CocoaPods is installed
   - Check iOS deployment target (16.0)

3. **Simulator limitations**
   - RoomPlan requires physical device
   - Simulator will show "not supported"

## Contributing

When contributing to this project:

1. Test on actual LiDAR-enabled devices
2. Verify compatibility handling for unsupported devices
3. Ensure data structure preservation
4. Follow Flutter and iOS best practices

## License

This is a proof-of-concept project demonstrating RoomPlan integration with Flutter.
