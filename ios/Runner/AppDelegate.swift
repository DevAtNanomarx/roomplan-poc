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
        print("=== LIDAR DETECTION START ===")
        print("DEBUG: Checking LiDAR capability for device: \(self.simpleModelName)")
        
        #if canImport(ARKit)
        print("DEBUG: ARKit available for LiDAR detection")
        
        if #available(iOS 14.0, *) {
            let sceneReconstructionSupported = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            print("DEBUG: iOS 14.0+ Scene reconstruction (.mesh) supported: \(sceneReconstructionSupported)")
            
            if sceneReconstructionSupported {
                print("DEBUG: ✅ LiDAR detected via scene reconstruction support")
                print("=== LIDAR DETECTION END ===")
                return true
            }
        }
        
        if #available(iOS 13.4, *) {
            let personSegmentationSupported = ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth)
            print("DEBUG: iOS 13.4+ Person segmentation with depth supported: \(personSegmentationSupported)")
            
            if personSegmentationSupported {
                print("DEBUG: ✅ LiDAR detected via person segmentation with depth")
                print("=== LIDAR DETECTION END ===")
                return true
            }
        }
        
        let basicARSupported = ARWorldTrackingConfiguration.isSupported
        print("DEBUG: Basic ARWorldTracking supported: \(basicARSupported)")
        print("DEBUG: ⚠️ Using fallback ARWorldTracking detection (less reliable)")
        print("=== LIDAR DETECTION END ===")
        return basicARSupported
        #else
        print("DEBUG: ARKit not available at compile time")
        print("=== LIDAR DETECTION END ===")
        return false
        #endif
    }
}

class SimpleRoomPlanHandler {
    
    static func checkRoomPlanSupport() -> [String: Any] {
        print("=== ROOMPLAN DEBUG START ===")
        
        var result: [String: Any] = [
            "platform": "iOS",
            "iOSVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.simpleModelName,
            "hasLiDAR": UIDevice.current.hasLiDARCapability,
            "frameworkAvailable": false,
            "isSupported": false
        ]
        
        print("DEBUG: iOS Version: \(UIDevice.current.systemVersion)")
        print("DEBUG: Device Model: \(UIDevice.current.simpleModelName)")
        print("DEBUG: Has LiDAR: \(UIDevice.current.hasLiDARCapability)")
        
        // Check iOS version requirement
        guard #available(iOS 16.0, *) else {
            print("DEBUG: iOS version too old for RoomPlan")
            result["error"] = "iOS 16.0 or later required for RoomPlan"
            result["debugInfo"] = "Current iOS version: \(UIDevice.current.systemVersion)"
            return result
        }
        
        print("DEBUG: iOS 16.0+ requirement met")
        
        // Check if RoomPlan framework is available
        #if canImport(RoomPlan)
        print("DEBUG: RoomPlan framework can be imported at compile time")
        result["frameworkAvailable"] = true
        
        // Method 1: Direct API access (preferred)
        print("DEBUG: Attempting direct RoomCaptureSession.isSupported access...")
        
        if #available(iOS 17.0, *) {
            print("DEBUG: iOS 17.0+ available, checking RoomCaptureSession.isSupported")
            let directSupport = RoomCaptureSession.isSupported
            print("DEBUG: RoomPlan is available via direct access?: \(directSupport)")
            
            result["isSupported"] = directSupport
            result["directAPICheck"] = directSupport
            
            if directSupport {
                result["debugInfo"] = "✅ RoomPlan fully supported via direct API access"
                print("DEBUG: ✅ RoomPlan supported via direct API")
            } else {
                result["error"] = "RoomPlan not supported on this device (missing LiDAR sensor)"
                result["debugInfo"] = "Direct API reports no support - device lacks LiDAR"
                print("DEBUG: ❌ RoomPlan not supported via direct API")
            }
        } else {
            print("DEBUG: iOS version < 17.0, using runtime reflection fallback")
            
            // Method 2: Runtime reflection fallback for iOS 16.x
            print("DEBUG: Attempting NSClassFromString('RoomCaptureSession')...")
            if let roomCaptureSessionClass = NSClassFromString("RoomCaptureSession") {
                print("DEBUG: ✅ RoomCaptureSession class found via NSClassFromString")
                
                if let isSupported = roomCaptureSessionClass.value(forKey: "isSupported") as? Bool {
                    print("DEBUG: ✅ KVC isSupported = \(isSupported)")
                    result["isSupported"] = isSupported
                    result["reflectionCheck"] = isSupported
                    
                    if isSupported {
                        result["debugInfo"] = "✅ RoomPlan supported via runtime reflection"
                    } else {
                        result["error"] = "RoomPlan not supported (missing LiDAR sensor)"
                        result["debugInfo"] = "Runtime reflection reports no support"
                    }
                } else {
                    print("DEBUG: ❌ KVC failed to get isSupported property")
                    result["error"] = "Unable to determine RoomPlan support status"
                    result["debugInfo"] = "KVC failed to get isSupported property"
                }
            } else {
                print("DEBUG: ❌ NSClassFromString failed for RoomCaptureSession")
                result["error"] = "RoomCaptureSession class not found"
                result["debugInfo"] = "NSClassFromString failed for RoomCaptureSession"
            }
        }
        
        // Additional debug checks
        print("DEBUG: Additional framework checks...")
        let bundlePath = Bundle.main.path(forResource: "RoomPlan", ofType: "framework")
        let frameworkBundle = Bundle(identifier: "com.apple.RoomPlan")
        
        print("DEBUG: RoomPlan framework bundle path: \(bundlePath ?? "nil")")
        print("DEBUG: RoomPlan framework bundle: \(frameworkBundle?.description ?? "nil")")
        
        // Check other RoomPlan classes
        let roomCaptureViewClass = NSClassFromString("RoomCaptureView")
        let capturedRoomClass = NSClassFromString("CapturedRoom")
        
        print("DEBUG: RoomCaptureView class found: \(roomCaptureViewClass != nil)")
        print("DEBUG: CapturedRoom class found: \(capturedRoomClass != nil)")
        
        result["roomCaptureViewFound"] = roomCaptureViewClass != nil
        result["capturedRoomFound"] = capturedRoomClass != nil
        
        #else
        print("DEBUG: ❌ RoomPlan framework NOT available at compile time")
        result["error"] = "RoomPlan framework not available at compile time"
        result["debugInfo"] = "RoomPlan not included in build (likely simulator or unsupported deployment target)"
        #endif
        
        print("DEBUG: Final result: \(result)")
        print("=== ROOMPLAN DEBUG END ===")
        
        return result
    }
    
    static func attemptRoomScan() -> FlutterError {
        print("=== ROOM SCAN ATTEMPT DEBUG START ===")
        
        guard #available(iOS 16.0, *) else {
            print("DEBUG: iOS version too old for RoomPlan scan")
            return FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                              message: "RoomPlan requires iOS 16.0 or later", 
                              details: nil)
        }
        
        print("DEBUG: iOS 16.0+ available for scanning")
        
        #if canImport(RoomPlan)
        print("DEBUG: RoomPlan framework available for scanning")
        
        // Use direct API if iOS 17.0+, otherwise fallback to reflection
        if #available(iOS 17.0, *) {
            print("DEBUG: Using direct API for scan attempt")
            let isSupported = RoomCaptureSession.isSupported
            print("DEBUG: RoomCaptureSession.isSupported = \(isSupported)")
            
            if isSupported {
                print("DEBUG: ✅ RoomPlan scan ready via direct API")
                return FlutterError(code: "FEATURE_READY", 
                                  message: "✅ RoomPlan is ready! Device supports room scanning.", 
                                  details: nil)
            } else {
                print("DEBUG: ❌ RoomPlan scan not supported via direct API")
                return FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                                  message: "RoomPlan is not supported on this device. Requires LiDAR sensor.", 
                                  details: nil)
            }
        } else {
            print("DEBUG: Using runtime reflection for scan attempt")
            guard let roomCaptureSessionClass = NSClassFromString("RoomCaptureSession") else {
                print("DEBUG: ❌ RoomCaptureSession class not found for scanning")
                return FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                                  message: "RoomPlan framework is not available on this device", 
                                  details: nil)
            }
            
            print("DEBUG: ✅ RoomCaptureSession class found for scanning")
            
            guard let isSupported = roomCaptureSessionClass.value(forKey: "isSupported") as? Bool,
                  isSupported else {
                print("DEBUG: ❌ RoomPlan not supported via reflection")
                return FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                                  message: "RoomPlan is not supported on this device. Requires LiDAR sensor.", 
                                  details: nil)
            }
            
            print("DEBUG: ✅ RoomPlan scan ready via reflection")
            return FlutterError(code: "FEATURE_READY", 
                              message: "✅ RoomPlan is ready! Device supports room scanning.", 
                              details: nil)
        }
        #else
        print("DEBUG: ❌ RoomPlan framework not available at compile time")
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




