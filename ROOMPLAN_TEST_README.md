# RoomPlan Device Test App

A minimal Flutter app to test RoomPlan API support and device capabilities on iOS devices.

## Features

This simple dashboard app checks and displays:

- **RoomPlan Support**: Whether the device supports Apple's RoomPlan API
- **LiDAR Detection**: Whether the device has a LiDAR sensor
- **Framework Availability**: Whether RoomPlan framework is loaded
- **Device Information**: iOS version, device model, platform details
- **Test Scan Function**: Basic test to verify RoomPlan initialization

## Requirements

### iOS Device Requirements for RoomPlan
- **iOS 16.0 or later**
- **LiDAR-enabled device**:
  - iPhone 12 Pro, 12 Pro Max
  - iPhone 13 Pro, 13 Pro Max
  - iPhone 14 Pro, 14 Pro Max
  - iPhone 15 Pro, 15 Pro Max
  - iPad Pro (4th gen) 11-inch and later
  - iPad Pro (5th gen) 12.9-inch and later

## App Structure

### Flutter App (`lib/main.dart`)
- Clean, minimal dashboard UI
- Real-time device capability checking
- Color-coded status indicators
- Device requirements information

### iOS Implementation (`ios/Runner/AppDelegate.swift`)
- Simple device detection using ARKit
- Runtime RoomPlan framework checking
- Minimal method channel handling
- Clean error reporting

## Key Components

### Device Detection
```swift
extension UIDevice {
    var hasLiDARCapability: Bool {
        // Uses ARKit to detect LiDAR support
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
}
```

### RoomPlan Support Check
```swift
class SimpleRoomPlanHandler {
    static func checkRoomPlanSupport() -> [String: Any] {
        // Runtime reflection to check RoomPlan availability
        // Verifies iOS version, framework, and device support
    }
}
```

## Usage

1. **Build and run** the Flutter app on an iOS device
2. **View the dashboard** to see device capabilities
3. **Test RoomPlan** using the test button (if supported)
4. **Check requirements** in the bottom info card

## Status Indicators

- 🟢 **Green**: Feature is supported and available
- 🔴 **Red**: Feature is not supported or unavailable  
- 🟡 **Gray**: Feature status unknown or checking

## Testing Scenarios

### ✅ Supported Device (e.g., iPhone 14 Pro)
- iOS 16.0+: ✅
- LiDAR: ✅
- RoomPlan Framework: ✅
- RoomPlan Support: ✅

### ❌ Unsupported Device (e.g., iPhone 11)
- iOS 16.0+: ✅
- LiDAR: ❌
- RoomPlan Framework: ✅
- RoomPlan Support: ❌

### ⚠️ Simulator
- iOS 16.0+: ✅
- LiDAR: ❌
- RoomPlan Framework: ❌
- RoomPlan Support: ❌

## References

- [Apple RoomPlan Documentation](https://developer.apple.com/augmented-reality/roomplan/)
- [WWDC22: Create parametric 3D room scans with RoomPlan](https://developer.apple.com/videos/play/wwdc2022/10127/)
- [Medium: Building a Room Scanning App with RoomPlan](https://medium.com/simform-engineering/building-a-room-scanning-app-with-the-roomplan-api-in-ios-a5e9f66cfaaf)

## Notes

- This is a **testing/diagnostic app** only
- Full room scanning implementation is not included
- Designed to quickly verify device compatibility
- Minimal dependencies and clean codebase 