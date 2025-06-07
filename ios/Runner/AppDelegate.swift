import Flutter
import UIKit

#if canImport(RoomPlan)
import RoomPlan
#endif

#if canImport(ARKit)
import ARKit
#endif

// MARK: - Simple Device Detection
extension UIDevice {
    var simpleModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode ?? "Unknown"
    }
    
    var hasLiDARCapability: Bool {
        #if canImport(ARKit)
        if #available(iOS 14.0, *) {
            return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        } else if #available(iOS 13.4, *) {
            return ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth)
        }
        return ARWorldTrackingConfiguration.isSupported
        #else
        return false
        #endif
    }
}

class SimpleRoomPlanHandler {
    
    static func checkRoomPlanSupport() -> [String: Any] {
        var result: [String: Any] = [
            "platform": "iOS",
            "iOSVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.simpleModelName,
            "hasLiDAR": UIDevice.current.hasLiDARCapability,
            "frameworkAvailable": false,
            "isSupported": false
        ]
        
        // Check iOS version requirement
        guard #available(iOS 16.0, *) else {
            result["error"] = "iOS 16.0 or later required for RoomPlan"
            result["debugInfo"] = "Current iOS version: \(UIDevice.current.systemVersion)"
            return result
        }
        
        // Check if RoomPlan framework is available
        #if canImport(RoomPlan)
        result["frameworkAvailable"] = true
        result["debugInfo"] = "RoomPlan framework imported successfully"
        
        // Use runtime reflection to check RoomPlan support
        if let roomCaptureSessionClass = NSClassFromString("RoomCaptureSession") {
            if let isSupported = roomCaptureSessionClass.value(forKey: "isSupported") as? Bool {
                result["isSupported"] = isSupported
                
                if isSupported {
                    result["debugInfo"] = "✅ RoomPlan fully supported on this device"
                } else {
                    result["error"] = "RoomPlan not supported on this device (missing LiDAR sensor)"
                    result["debugInfo"] = "Device lacks required LiDAR hardware for RoomPlan"
                }
            } else {
                result["error"] = "Unable to determine RoomPlan support status"
                result["debugInfo"] = "KVC failed to get isSupported property"
            }
        } else {
            result["error"] = "RoomCaptureSession class not found"
            result["debugInfo"] = "NSClassFromString failed for RoomCaptureSession"
        }
        #else
        result["error"] = "RoomPlan framework not available at compile time"
        result["debugInfo"] = "RoomPlan not included in build (likely simulator or unsupported deployment target)"
        #endif
        
        return result
    }
    
    static func attemptRoomScan() -> FlutterError {
        guard #available(iOS 16.0, *) else {
            return FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                              message: "RoomPlan requires iOS 16.0 or later", 
                              details: nil)
        }
        
        #if canImport(RoomPlan)
        guard let roomCaptureSessionClass = NSClassFromString("RoomCaptureSession") else {
            return FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                              message: "RoomPlan framework is not available on this device", 
                              details: nil)
        }
        
        guard let isSupported = roomCaptureSessionClass.value(forKey: "isSupported") as? Bool,
              isSupported else {
            return FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                              message: "RoomPlan is not supported on this device. Requires LiDAR sensor.", 
                              details: nil)
        }
        
        // If we get here, RoomPlan is supported
        return FlutterError(code: "FEATURE_READY", 
                          message: "✅ RoomPlan is ready! Device supports room scanning.", 
                          details: nil)
        #else
        return FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                          message: "RoomPlan framework not available", 
                          details: nil)
        #endif
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let roomPlanChannel = FlutterMethodChannel(name: "roomplan_flutter_poc/roomplan",
                                              binaryMessenger: controller.binaryMessenger)
    
    roomPlanChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      self.handleMethodCall(call: call, result: result)
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isRoomPlanSupported":
      checkRoomPlanSupport(result: result)
    case "startRoomScan":
      startRoomScan(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func checkRoomPlanSupport(result: @escaping FlutterResult) {
    let deviceInfo = SimpleRoomPlanHandler.checkRoomPlanSupport()
    
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
      let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
      result(jsonString)
    } catch {
      result(FlutterError(code: "JSON_ERROR", 
                        message: "Failed to serialize device info", 
                        details: error.localizedDescription))
    }
  }
  
  private func startRoomScan(result: @escaping FlutterResult) {
    let error = SimpleRoomPlanHandler.attemptRoomScan()
    result(error)
  }
}




