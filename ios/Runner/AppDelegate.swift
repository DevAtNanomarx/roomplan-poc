import Flutter
import UIKit
import QuickLook

// Try to import RoomPlan and ARKit
#if canImport(RoomPlan)
import RoomPlan
#endif

#if canImport(ARKit)
import ARKit
#endif

// MARK: - Device Model Detection
extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        let identifier = modelCode ?? "Unknown"
        
        func mapToDevice(identifier: String) -> String {
            #if os(iOS)
            switch identifier {
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone8,4":                               return "iPhone SE (1st generation)"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPhone12,8":                              return "iPhone SE (2nd generation)"
            case "iPhone13,1":                              return "iPhone 12 mini"
            case "iPhone13,2":                              return "iPhone 12"
            case "iPhone13,3":                              return "iPhone 12 Pro"
            case "iPhone13,4":                              return "iPhone 12 Pro Max"
            case "iPhone14,2":                              return "iPhone 13 mini"
            case "iPhone14,3":                              return "iPhone 13"
            case "iPhone14,4":                              return "iPhone 13 Pro"
            case "iPhone14,5":                              return "iPhone 13 Pro Max"
            case "iPhone14,6":                              return "iPhone SE (3rd generation)"
            case "iPhone14,7":                              return "iPhone 14"
            case "iPhone14,8":                              return "iPhone 14 Plus"
            case "iPhone15,2":                              return "iPhone 14 Pro"
            case "iPhone15,3":                              return "iPhone 14 Pro Max"
            case "iPhone15,4":                              return "iPhone 15"
            case "iPhone15,5":                              return "iPhone 15 Plus"
            case "iPhone16,1":                              return "iPhone 15 Pro"
            case "iPhone16,2":                              return "iPhone 15 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad11,6", "iPad11,7":                    return "iPad (8th generation)"
            case "iPad12,1", "iPad12,2":                    return "iPad (9th generation)"
            case "iPad13,18", "iPad13,19":                  return "iPad (10th generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad14,1", "iPad14,2":                    return "iPad mini (6th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
            case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"
            case "iPad13,1", "iPad13,2":                    return "iPad Pro (11-inch) (3rd generation)"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro (12.9-inch) (5th generation)"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro (11-inch) (4th generation)"
            case "iPad14,3", "iPad14,4", "iPad14,5", "iPad14,6": return "iPad Pro (12.9-inch) (6th generation)"
            case "iPad11,3", "iPad11,4":                    return "iPad Air (3rd generation)"
            case "iPad13,1", "iPad13,2":                    return "iPad Air (4th generation)"
            case "iPad13,16", "iPad13,17":                  return "iPad Air (5th generation)"
            case "i386", "x86_64", "arm64":                 return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3":                              return "Apple TV 4th generation"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default:                                        return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }
    
    var hasLiDAR: Bool {
        // Check for actual LiDAR hardware capability using ARKit
        guard #available(iOS 13.0, *) else { return false }
        
        #if canImport(ARKit)
        // Primary check: Scene reconstruction support (iOS 14+) indicates LiDAR availability
        if #available(iOS 14.0, *) {
            // Scene reconstruction with mesh is only available on LiDAR devices
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                return true
            }
        }
        
        // Secondary check: For iOS 13+ devices, check for enhanced depth capabilities
        // This is more reliable than model name checking
        if #available(iOS 13.4, *) {
            // Check if the device supports people occlusion, which requires depth sensing capabilities
            // typically found on LiDAR devices
            return ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth)
        }
        
        // Fallback: Basic ARWorldTracking support (less reliable indicator)
        return ARWorldTrackingConfiguration.isSupported
        #else
        return false
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
      self.handleMethodCall(call: call, result: result, controller: controller)
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult, controller: FlutterViewController) {
    switch call.method {
    case "isRoomPlanSupported":
      checkRoomPlanSupport(result: result)
    case "startRoomScan":
      startRoomScan(result: result, controller: controller)
    case "getSavedScans":
      getSavedScans(result: result)
          case "deleteSavedScan":
        deleteSavedScan(call: call, result: result)
      case "getSavedUSDZFiles":
        getSavedUSDZFiles(result: result)
      case "uploadUSDZFile":
        uploadUSDZFile(call: call, result: result)
      case "openUSDZFile":
        openUSDZFile(call: call, result: result)
      case "deleteUSDZFile":
        deleteUSDZFile(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
  }
  
  private func checkRoomPlanSupport(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      print("DEBUG: Checking RoomPlan support on iOS \(UIDevice.current.systemVersion)")
      
      // Multiple ways to check RoomPlan availability
      let bundlePath = Bundle.main.path(forResource: "RoomPlan", ofType: "framework")
      let classExists = NSClassFromString("RoomCaptureController") != nil
      let frameworkBundle = Bundle(identifier: "com.apple.RoomPlan")
      
      print("DEBUG: Bundle path: \(bundlePath ?? "nil")")
      print("DEBUG: Class exists: \(classExists)")
      print("DEBUG: Framework bundle: \(frameworkBundle?.description ?? "nil")")
      
      // Check if RoomPlan framework exists at runtime
      guard classExists || bundlePath != nil || frameworkBundle != nil else {
        print("DEBUG: RoomPlan framework not found in bundle")
        
        let deviceInfo = [
          "isSupported": false,
          "iOSVersion": UIDevice.current.systemVersion,
          "deviceModel": UIDevice.current.modelName,
          "hasLiDAR": UIDevice.current.hasLiDAR,
          "frameworkAvailable": false,
          "error": "RoomPlan framework not available at runtime",
          "debugInfo": "Framework not found in app bundle. This may indicate the app wasn't built with RoomPlan support or is running on a system without RoomPlan."
        ] as [String: Any]
        
        do {
          let jsonData = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
          let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
          result(jsonString)
        } catch {
          result("{\"isSupported\": false, \"error\": \"RoomPlan framework not available\"}")
        }
        return
      }
      
      print("DEBUG: RoomPlan class found, checking support")
      
      // Use runtime reflection to check RoomPlan support
      guard let roomCaptureControllerClass = NSClassFromString("RoomCaptureController") else {
        let deviceInfo = [
          "isSupported": false,
          "iOSVersion": UIDevice.current.systemVersion,
          "deviceModel": UIDevice.current.modelName,
          "hasLiDAR": UIDevice.current.hasLiDAR,
          "frameworkAvailable": false,
          "error": "RoomCaptureController class not found",
          "debugInfo": "NSClassFromString failed for RoomCaptureController"
        ] as [String: Any]
        
        do {
          let jsonData = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
          let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
          result(jsonString)
        } catch {
          result("{\"isSupported\": false, \"error\": \"RoomPlan framework not available\"}")
        }
        return
      }
      
      // Use KVC to safely call isSupported
      guard let isSupported = roomCaptureControllerClass.value(forKey: "isSupported") as? Bool else {
        print("DEBUG: Could not get isSupported property")
        
        let deviceInfo = [
          "isSupported": false,
          "iOSVersion": UIDevice.current.systemVersion,
          "deviceModel": UIDevice.current.modelName,
          "hasLiDAR": UIDevice.current.hasLiDAR,
          "frameworkAvailable": true,
          "error": "Could not determine RoomPlan support",
          "debugInfo": "KVC failed for isSupported property"
        ] as [String: Any]
        
        do {
          let jsonData = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
          let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
          result(jsonString)
        } catch {
          result("{\"isSupported\": false, \"error\": \"Could not determine RoomPlan support\"}")
        }
        return
      }
      
      print("DEBUG: RoomPlan isSupported = \(isSupported)")
      
      let deviceInfo = [
        "isSupported": isSupported,
        "iOSVersion": UIDevice.current.systemVersion,
        "deviceModel": UIDevice.current.modelName,
        "hasLiDAR": UIDevice.current.hasLiDAR,
        "frameworkAvailable": true,
        "debugInfo": "Successfully checked RoomPlan support via runtime reflection"
      ] as [String: Any]
      
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        result(jsonString)
      } catch {
        result("{\"isSupported\": false, \"error\": \"JSON serialization failed\"}")
      }
    } else {
      let deviceInfo = [
        "isSupported": false,
        "iOSVersion": UIDevice.current.systemVersion,
        "deviceModel": UIDevice.current.modelName,
        "hasLiDAR": UIDevice.current.hasLiDAR,
        "frameworkAvailable": false,
        "error": "iOS 16.0+ required"
      ] as [String: Any]
      
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        result(jsonString)
      } catch {
        result("{\"isSupported\": false, \"error\": \"iOS version too old\"}")
      }
    }
  }
  
  private func startRoomScan(result: @escaping FlutterResult, controller: FlutterViewController) {
    guard #available(iOS 16.0, *) else {
      result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                        message: "RoomPlan requires iOS 16.0 or later", 
                        details: nil))
      return
    }
    
    // Use runtime reflection to check RoomPlan support safely
    guard let roomCaptureControllerClass = NSClassFromString("RoomCaptureController") else {
      result(FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                        message: "RoomPlan framework is not available on this device", 
                        details: nil))
      return
    }
    
    // Use KVC to safely call isSupported
    guard let isSupported = roomCaptureControllerClass.value(forKey: "isSupported") as? Bool,
          isSupported else {
      result(FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                        message: "RoomPlan is not supported on this device. Requires LiDAR sensor.", 
                        details: nil))
      return
    }
    
    // RoomPlan is supported - for now return an error indicating this feature is under development
    result(FlutterError(code: "FEATURE_NOT_IMPLEMENTED", 
                      message: "RoomPlan scanning is detected and supported on this device. Full implementation is in development.", 
                      details: nil))
  }
  
  private func saveRoomData(_ roomData: String, result: @escaping FlutterResult) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let timestamp = Int(Date().timeIntervalSince1970)
    let fileName = "room_scan_\(timestamp).json"
    let fileURL = documentsPath.appendingPathComponent(fileName)
    
    do {
      try roomData.write(to: fileURL, atomically: true, encoding: .utf8)
      
      // Return both the scan data and the file info
      let responseData = [
        "scanData": roomData,
        "fileName": fileName,
        "filePath": fileURL.path,
        "timestamp": timestamp
      ] as [String: Any]
      
      let jsonData = try JSONSerialization.data(withJSONObject: responseData, options: [])
      let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
      result(jsonString)
    } catch {
      result(FlutterError(code: "SAVE_ERROR", 
                        message: "Failed to save room data: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func getSavedScans(result: @escaping FlutterResult) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey], options: [])
      
      let roomScanFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("room_scan_") && $0.pathExtension == "json" }
      
      var savedScans: [[String: Any]] = []
      
      for fileURL in roomScanFiles {
        do {
          let fileData = try Data(contentsOf: fileURL)
          let roomDataString = String(data: fileData, encoding: .utf8) ?? ""
          let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
          let creationDate = attributes[.creationDate] as? Date ?? Date()
          
          let scanInfo = [
            "fileName": fileURL.lastPathComponent,
            "filePath": fileURL.path,
            "timestamp": Int(creationDate.timeIntervalSince1970),
            "scanData": roomDataString
          ] as [String: Any]
          
          savedScans.append(scanInfo)
        } catch {
          print("Error reading file \(fileURL.lastPathComponent): \(error)")
        }
      }
      
      // Sort by timestamp (newest first)
      savedScans.sort { ($0["timestamp"] as? Int ?? 0) > ($1["timestamp"] as? Int ?? 0) }
      
      let jsonData = try JSONSerialization.data(withJSONObject: savedScans, options: [])
      let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
      result(jsonString)
    } catch {
      result(FlutterError(code: "READ_ERROR", 
                        message: "Failed to read saved scans: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func deleteSavedScan(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let fileName = arguments["fileName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", 
                        message: "fileName is required", 
                        details: nil))
      return
    }
    
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsPath.appendingPathComponent(fileName)
    
    do {
      try FileManager.default.removeItem(at: fileURL)
      result(true)
    } catch {
      result(FlutterError(code: "DELETE_ERROR", 
                        message: "Failed to delete file: \(error.localizedDescription)", 
                        details: nil))
    }
  }
}

  // MARK: - USDZ File Management
  
  private func getUSDZDirectory() -> URL {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let usdzDirectory = documentsPath.appendingPathComponent("USDZ")
    
    // Create directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: usdzDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: usdzDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("Failed to create USDZ directory: \(error)")
      }
    }
    
    return usdzDirectory
  }
  
  private func getSavedUSDZFiles(result: @escaping FlutterResult) {
    let usdzDirectory = getUSDZDirectory()
    var usdzFiles: [[String: Any]] = []
    
    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(at: usdzDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
      
      for fileURL in fileURLs {
        if fileURL.pathExtension.lowercased() == "usdz" {
          do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            
            let fileInfo: [String: Any] = [
              "fileName": fileURL.lastPathComponent,
              "timestamp": Int(creationDate.timeIntervalSince1970)
            ]
            usdzFiles.append(fileInfo)
          } catch {
            print("Error getting file attributes for \(fileURL.lastPathComponent): \(error)")
          }
        }
      }
      
      // Sort by timestamp (newest first)
      usdzFiles.sort { ($0["timestamp"] as? Int ?? 0) > ($1["timestamp"] as? Int ?? 0) }
      
      let jsonData = try JSONSerialization.data(withJSONObject: usdzFiles, options: [])
      let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
      result(jsonString)
    } catch {
      result(FlutterError(code: "FILE_SYSTEM_ERROR", 
                        message: "Failed to list USDZ files: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func uploadUSDZFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let filePath = args["filePath"] as? String,
          let fileName = args["fileName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", 
                        message: "Missing required arguments: filePath and fileName", 
                        details: nil))
      return
    }
    
    let sourceURL = URL(fileURLWithPath: filePath)
    let usdzDirectory = getUSDZDirectory()
    let destinationURL = usdzDirectory.appendingPathComponent(fileName)
    
    do {
      // Remove existing file if it exists
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }
      
      // Copy file to documents directory
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
      result("USDZ file uploaded successfully")
    } catch {
      result(FlutterError(code: "FILE_COPY_ERROR", 
                        message: "Failed to copy USDZ file: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func openUSDZFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let fileName = args["fileName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", 
                        message: "Missing required argument: fileName", 
                        details: nil))
      return
    }
    
    let usdzDirectory = getUSDZDirectory()
    let fileURL = usdzDirectory.appendingPathComponent(fileName)
    
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      result(FlutterError(code: "FILE_NOT_FOUND", 
                        message: "USDZ file not found: \(fileName)", 
                        details: nil))
      return
    }
    
    DispatchQueue.main.async {
      // Use QLPreviewController or AR Quick Look to display the USDZ file
      if #available(iOS 12.0, *) {
        let previewVC = ARQuickLookViewController()
        previewVC.fileURL = fileURL
        
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
          viewController.present(previewVC, animated: true) {
            result("USDZ file opened in AR Quick Look")
          }
        } else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", 
                            message: "Could not find view controller to present AR Quick Look", 
                            details: nil))
        }
      } else {
        result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                          message: "AR Quick Look requires iOS 12.0 or later", 
                          details: nil))
      }
    }
  }
  
  private func deleteUSDZFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let fileName = args["fileName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", 
                        message: "Missing required argument: fileName", 
                        details: nil))
      return
    }
    
    let usdzDirectory = getUSDZDirectory()
    let fileURL = usdzDirectory.appendingPathComponent(fileName)
    
    do {
      try FileManager.default.removeItem(at: fileURL)
      result("USDZ file deleted successfully")
    } catch {
      result(FlutterError(code: "FILE_DELETE_ERROR", 
                        message: "Failed to delete USDZ file: \(error.localizedDescription)", 
                        details: nil))
    }
  }

// MARK: - AR Quick Look Controller

@available(iOS 12.0, *)
class ARQuickLookViewController: UIViewController {
  var fileURL: URL?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let fileURL = fileURL else {
      dismiss(animated: true)
      return
    }
    
    // Use QLPreviewController for USDZ files
    let previewController = QLPreviewController()
    previewController.dataSource = self
    previewController.delegate = self
    
    // Present as child view controller
    addChild(previewController)
    view.addSubview(previewController.view)
    previewController.view.frame = view.bounds
    previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    previewController.didMove(toParent: self)
    
    // Add close button
    let closeButton = UIButton(type: .system)
    closeButton.setTitle("Close", for: .normal)
    closeButton.setTitleColor(.white, for: .normal)
    closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    closeButton.layer.cornerRadius = 8
    closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    
    view.addSubview(closeButton)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      closeButton.widthAnchor.constraint(equalToConstant: 80),
      closeButton.heightAnchor.constraint(equalToConstant: 40)
    ])
  }
  
  @objc private func closeButtonTapped() {
    dismiss(animated: true)
  }
}

@available(iOS 12.0, *)
extension ARQuickLookViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }
  
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return fileURL! as QLPreviewItem
  }
}




