import Flutter
import UIKit
import QuickLook
#if canImport(RoomPlan)
import RoomPlan
import ARKit
#endif

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
      // For universal compatibility, we'll check if RoomPlan classes exist at runtime
      if NSClassFromString("RoomCaptureController") != nil {
        // RoomPlan framework exists but we can't call isSupported without importing
        // Return false for simulator, true for real devices (will be validated later)
        #if targetEnvironment(simulator)
        result(false)
        #else
        // On real devices, assume supported if iOS 16+ and class exists
        // This is a simplified check - in production you'd want more thorough validation
        result(true)
        #endif
      } else {
        // RoomPlan framework not available
        result(false)
      }
    } else {
      result(false)
    }
  }
  
  private func startRoomScan(result: @escaping FlutterResult, controller: FlutterViewController) {
    guard #available(iOS 16.0, *) else {
      result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                        message: "RoomPlan requires iOS 16.0 or later", 
                        details: nil))
      return
    }
    
    // Check if RoomPlan is actually available at runtime
    guard NSClassFromString("RoomCaptureController") != nil else {
      result(FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                        message: "RoomPlan framework is not available on this device", 
                        details: nil))
      return
    }
    
    // For now, we'll show an error message since we're avoiding compile-time RoomPlan usage
    result(FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                      message: "RoomPlan scanning is not implemented in this build. Requires LiDAR sensor and proper app signing.", 
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


