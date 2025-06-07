import Flutter
import UIKit
import simd

#if canImport(RoomPlan)
import RoomPlan
#endif

#if canImport(ARKit)
import ARKit
#endif

#if canImport(QuickLook)
import QuickLook
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
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
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
      checkRoomPlanSupported(result: result)
    case "startRoomScan":
      startRoomScan(result: result)
    case "getSavedUSDZFiles":
      getSavedUSDZFiles(result: result)
    case "openUSDZFile":
      openUSDZFile(call: call, result: result)
    case "deleteUSDZFile":
      deleteUSDZFile(call: call, result: result)
    case "importUSDZFile":
      importUSDZFile(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func checkRoomPlanSupported(result: @escaping FlutterResult) {
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
    // First check if RoomPlan is supported
    let supportCheck = SimpleRoomPlanHandler.attemptRoomScan()
    
    if supportCheck.code != "FEATURE_READY" {
      result(supportCheck)
      return
    }
    
        // RoomPlan is supported, start actual scanning
    print("DEBUG: Starting actual room scan...")
    
    guard #available(iOS 16.0, *) else {
      result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                        message: "RoomPlan requires iOS 16.0 or later", 
                        details: nil))
      return
    }
    
    #if canImport(RoomPlan)
    DispatchQueue.main.async {
      let roomScanViewController = RoomScanViewController()
      roomScanViewController.onScanComplete = { [weak self] success, message, filePath in
        DispatchQueue.main.async {
          if success {
            let resultMap: [String: Any] = [
              "success": true, 
              "message": message, 
              "filePath": filePath ?? "",
              "scanComplete": true
            ]
            result(resultMap)
          } else {
            result(FlutterError(code: "SCAN_FAILED", message: message, details: nil))
          }
        }
      }
      
      if let viewController = UIApplication.shared.keyWindow?.rootViewController {
        viewController.present(roomScanViewController, animated: true)
        // Don't call result here - wait for the scan to complete
        print("DEBUG: Room scan view controller presented, waiting for completion...")
      } else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", 
                          message: "Could not find view controller to present scanner", 
                          details: nil))
      }
    }
    #else
    result(FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                      message: "RoomPlan framework not available", 
                      details: nil))
    #endif
}

  // MARK: - USDZ File Management
  
  private func getUSDZDirectory() -> URL {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let usdzDirectory = documentsPath.appendingPathComponent("RoomScans")
    
    // Create directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: usdzDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: usdzDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("Failed to create RoomScans directory: \(error)")
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
              "timestamp": Int(creationDate.timeIntervalSince1970),
              "filePath": fileURL.path
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
      let savedFileViewController = SavedUSDZViewController()
      savedFileViewController.fileName = fileName
      savedFileViewController.fileURL = fileURL
      savedFileViewController.onClose = {
        result("USDZ file viewer closed")
      }
      
      if let viewController = UIApplication.shared.keyWindow?.rootViewController {
        viewController.present(savedFileViewController, animated: true)
      } else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", 
                          message: "Could not find view controller to present USDZ viewer", 
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
  
  private func importUSDZFile(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.pixar.universal-scene-description-mobile"], in: .import)
      documentPicker.delegate = self
      documentPicker.modalPresentationStyle = .formSheet
      documentPicker.allowsMultipleSelection = false
      
      // Store the result callback for later use
      self.importResultCallback = result
      
      if let viewController = UIApplication.shared.keyWindow?.rootViewController {
        viewController.present(documentPicker, animated: true) {
          print("DEBUG: USDZ import document picker presented")
        }
      } else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", 
                          message: "Could not find view controller to present document picker", 
                          details: nil))
      }
    }
  }
  
  // Store the import result callback
  private var importResultCallback: FlutterResult?
}

// MARK: - AppDelegate UIDocumentPickerDelegate

extension AppDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    print("DEBUG: 📁 AppDelegate document picker completed with URLs: \(urls)")
    
    guard let importResult = importResultCallback else {
      print("DEBUG: No import result callback stored")
      return
    }
    
    guard let sourceURL = urls.first else {
      print("DEBUG: ❌ No URL returned from import document picker")
      importResult(FlutterError(code: "NO_FILE_SELECTED", 
                              message: "No file was selected for import", 
                              details: nil))
      importResultCallback = nil
      return
    }
    
    // Check if it's a USDZ file
    guard sourceURL.pathExtension.lowercased() == "usdz" else {
      print("DEBUG: ❌ Selected file is not a USDZ file: \(sourceURL.pathExtension)")
      importResult(FlutterError(code: "INVALID_FILE_TYPE", 
                              message: "Please select a USDZ file", 
                              details: nil))
      importResultCallback = nil
      return
    }
    
    // Copy the file to our RoomScans directory
    let usdzDirectory = getUSDZDirectory()
    let fileName = sourceURL.lastPathComponent
    let destinationURL = usdzDirectory.appendingPathComponent(fileName)
    
    // If file already exists, add timestamp to make it unique
    var finalDestinationURL = destinationURL
    if FileManager.default.fileExists(atPath: destinationURL.path) {
      let timestamp = Int(Date().timeIntervalSince1970)
      let nameWithoutExtension = (fileName as NSString).deletingPathExtension
      let fileExtension = (fileName as NSString).pathExtension
      let uniqueFileName = "\(nameWithoutExtension)_\(timestamp).\(fileExtension)"
      finalDestinationURL = usdzDirectory.appendingPathComponent(uniqueFileName)
    }
    
    do {
      // Get access to the security-scoped resource
      guard sourceURL.startAccessingSecurityScopedResource() else {
        throw NSError(domain: "FileAccess", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access selected file"])
      }
      defer { sourceURL.stopAccessingSecurityScopedResource() }
      
      // Copy the file
      try FileManager.default.copyItem(at: sourceURL, to: finalDestinationURL)
      print("DEBUG: ✅ USDZ file imported successfully to: \(finalDestinationURL.path)")
      
      let result: [String: Any] = [
        "success": true,
        "fileName": finalDestinationURL.lastPathComponent,
        "filePath": finalDestinationURL.path,
        "message": "USDZ file imported successfully"
      ]
      
      importResult(result)
    } catch {
      print("DEBUG: ❌ Failed to import USDZ file: \(error)")
      importResult(FlutterError(code: "IMPORT_FAILED", 
                              message: "Failed to import USDZ file: \(error.localizedDescription)", 
                              details: nil))
    }
    
    importResultCallback = nil
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    print("DEBUG: 📁 AppDelegate document picker was cancelled")
    importResultCallback?(FlutterError(code: "USER_CANCELLED", 
                                     message: "File import was cancelled by user", 
                                     details: nil))
    importResultCallback = nil
  }
}

// MARK: - Room Scanning View Controller

#if canImport(RoomPlan)
@available(iOS 16.0, *)
class RoomScanViewController: UIViewController {
  private var roomCaptureView: RoomCaptureView!
  private var isScanning = false
  
  var onScanComplete: ((Bool, String, String?) -> Void)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupRoomCapture()
    setupUI()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startScanning()
  }
  
  private func setupRoomCapture() {
    print("DEBUG: Setting up RoomCaptureView...")
    
    // Create RoomCaptureView - it has its own built-in captureSession
    roomCaptureView = RoomCaptureView(frame: view.bounds)
    roomCaptureView.delegate = self
    roomCaptureView.captureSession.delegate = self
    view.addSubview(roomCaptureView)
    
    print("DEBUG: RoomCaptureView setup complete")
  }
  
  private func setupUI() {
    view.backgroundColor = .black
    
    // Add close button
    let closeButton = UIButton(type: .system)
    closeButton.setTitle("Cancel", for: .normal)
    closeButton.setTitleColor(.white, for: .normal)
    closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    closeButton.layer.cornerRadius = 8
    closeButton.addTarget(self, action: #selector(cancelScan), for: .touchUpInside)
    
    view.addSubview(closeButton)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      closeButton.widthAnchor.constraint(equalToConstant: 80),
      closeButton.heightAnchor.constraint(equalToConstant: 40)
    ])
    
    // Add done button
    let doneButton = UIButton(type: .system)
    doneButton.setTitle("Done", for: .normal)
    doneButton.setTitleColor(.white, for: .normal)
    doneButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
    doneButton.layer.cornerRadius = 8
    doneButton.addTarget(self, action: #selector(finishScan), for: .touchUpInside)
    
    view.addSubview(doneButton)
    doneButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      doneButton.widthAnchor.constraint(equalToConstant: 80),
      doneButton.heightAnchor.constraint(equalToConstant: 40)
    ])
  }
  
  private func startScanning() {
    guard !isScanning else { return }
    
    print("DEBUG: Starting room capture session...")
    var config = RoomCaptureSession.Configuration()
    config.isCoachingEnabled = true
    
    roomCaptureView.captureSession.run(configuration: config)
    isScanning = true
    
    print("DEBUG: Room scanning started")
  }
  
  @objc private func cancelScan() {
    print("DEBUG: Cancelling room scan...")
    roomCaptureView.captureSession.stop()
    dismiss(animated: true) {
      self.onScanComplete?(false, "Scan cancelled by user", nil)
    }
  }
  
  @objc private func finishScan() {
    print("DEBUG: Finishing room scan...")
    roomCaptureView.captureSession.stop()
    isScanning = false
    
    // Wait a moment for the session to process final data, then show preview
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      if let room = self.latestCapturedRoom {
        print("DEBUG: Using latest captured room data - showing preview")
        self.showPreview(for: room)
      } else {
        print("DEBUG: No room data available - scan may not be complete")
        self.dismiss(animated: true) {
          self.onScanComplete?(false, "Scan incomplete - please scan more of the room", nil)
        }
      }
    }
  }
  
  private func showPreview(for room: CapturedRoom) {
    print("DEBUG: 🎉 Showing tabbed preview for captured room!")
    print("DEBUG: Room has \(room.objects.count) objects, \(room.walls.count) walls, \(room.openings.count) openings")
    
    // Update UI for preview mode
    view.subviews.forEach { $0.removeFromSuperview() }
    view.backgroundColor = UIColor.systemBackground
    
    // Create tab bar controller
    let tabBarController = UITabBarController()
    tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
    
    // Create 3D Preview tab
    let previewViewController = create3DPreviewViewController(for: room)
    previewViewController.tabBarItem = UITabBarItem(title: "3D Preview", image: UIImage(systemName: "cube"), tag: 0)
    
    // Create Measurements tab
    let measurementsViewController = createMeasurementsViewController(for: room)
    measurementsViewController.tabBarItem = UITabBarItem(title: "Measurements", image: UIImage(systemName: "ruler"), tag: 1)
    
    // Set up tab bar controller
    tabBarController.viewControllers = [previewViewController, measurementsViewController]
    tabBarController.selectedIndex = 0 // Start with 3D preview
    
    // Add tab bar controller as child
    addChild(tabBarController)
    view.addSubview(tabBarController.view)
    tabBarController.didMove(toParent: self)
    
    // Set up constraints for tab bar controller (leave space for buttons)
    NSLayoutConstraint.activate([
      tabBarController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBarController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
    ])
    
    // Add Cancel button
    let cancelButton = UIButton(type: .system)
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.setTitleColor(.white, for: .normal)
    cancelButton.backgroundColor = UIColor.systemRed
    cancelButton.layer.cornerRadius = 8
    cancelButton.addTarget(self, action: #selector(cancelPreview), for: .touchUpInside)
    
    view.addSubview(cancelButton)
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      cancelButton.widthAnchor.constraint(equalToConstant: 100),
      cancelButton.heightAnchor.constraint(equalToConstant: 44)
    ])
    
    // Add Save button
    let saveButton = UIButton(type: .system)
    saveButton.setTitle("Save", for: .normal)
    saveButton.setTitleColor(.white, for: .normal)
    saveButton.backgroundColor = UIColor.systemBlue
    saveButton.layer.cornerRadius = 8
    saveButton.addTarget(self, action: #selector(saveToFile), for: .touchUpInside)
    
    view.addSubview(saveButton)
    saveButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      saveButton.widthAnchor.constraint(equalToConstant: 100),
      saveButton.heightAnchor.constraint(equalToConstant: 44)
    ])
    
    // Store the room for saving
    self.latestCapturedRoom = room
  }
  
  private func create3DPreviewViewController(for room: CapturedRoom) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = UIColor.systemBackground
    
    // Create temporary USDZ for preview
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempFileName = "preview_\(UUID().uuidString).usdz"
    let tempFileURL = tempDirectory.appendingPathComponent(tempFileName)
    
    do {
      try room.export(to: tempFileURL)
      
      #if canImport(QuickLook)
      if #available(iOS 12.0, *) {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        
        // Store the temp file URL for the preview
        self.tempPreviewURL = tempFileURL
        
        // Add preview controller as child
        viewController.addChild(previewController)
        viewController.view.addSubview(previewController.view)
        previewController.view.frame = viewController.view.bounds
        previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewController.didMove(toParent: viewController)
      } else {
        addFallback3DMessage(to: viewController)
      }
      #else
      addFallback3DMessage(to: viewController)
      #endif
    } catch {
      print("DEBUG: Failed to create 3D preview: \(error)")
      addFallback3DMessage(to: viewController)
    }
    
    return viewController
  }
  
  private func addFallback3DMessage(to viewController: UIViewController) {
    let label = UILabel()
    label.text = "3D Preview unavailable\nRoom scan saved successfully!"
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = UIColor.secondaryLabel
    viewController.view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
    ])
  }
  
  private func createMeasurementsViewController(for room: CapturedRoom) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = UIColor.systemBackground
    
    // Create scroll view for measurements
    let scrollView = UIScrollView()
    scrollView.backgroundColor = UIColor.systemBackground
    viewController.view.addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    
    // Create content view
    let contentView = UIView()
    scrollView.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    
    // Create measurements text
    let measurementsLabel = UILabel()
    measurementsLabel.numberOfLines = 0
    measurementsLabel.textColor = UIColor.label
    measurementsLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    measurementsLabel.textAlignment = .left
    
    var measurementsText = generateCompleteMeasurements(for: room)
    measurementsLabel.text = measurementsText
    
    contentView.addSubview(measurementsLabel)
    measurementsLabel.translatesAutoresizingMaskIntoConstraints = false
    
    // Set up constraints
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
      
      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      
      measurementsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      measurementsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      measurementsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      measurementsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
    ])
    
    return viewController
  }
  
  private func generateCompleteMeasurements(for room: CapturedRoom) -> String {
    var text = "🏠 COMPLETE ROOM MEASUREMENTS\n"
    text += "=" + String(repeating: "=", count: 35) + "\n\n"
    
    // Room dimensions (estimated from walls)
    if !room.walls.isEmpty {
      text += "📐 ROOM DIMENSIONS\n"
      text += "-" + String(repeating: "-", count: 20) + "\n"
      
      var minX: Float = Float.greatestFiniteMagnitude
      var maxX: Float = -Float.greatestFiniteMagnitude
      var minZ: Float = Float.greatestFiniteMagnitude
      var maxZ: Float = -Float.greatestFiniteMagnitude
      
      for wall in room.walls {
        let dimensions = wall.dimensions
        let transform = wall.transform
        // Extract position from transform matrix
        let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        minX = min(minX, position.x - dimensions.x/2)
        maxX = max(maxX, position.x + dimensions.x/2)
        minZ = min(minZ, position.z - dimensions.z/2)
        maxZ = max(maxZ, position.z + dimensions.z/2)
      }
      
      let roomWidth = maxX - minX
      let roomDepth = maxZ - minZ
      
      text += "Overall Room Size: \(String(format: "%.1f", roomWidth))m × \(String(format: "%.1f", roomDepth))m\n\n"
    }
    
    // Walls
    text += "🧱 WALLS (\(room.walls.count) detected)\n"
    text += "-" + String(repeating: "-", count: 25) + "\n"
    for (index, wall) in room.walls.enumerated() {
      let dimensions = wall.dimensions
      text += "Wall \(index + 1):\n"
      text += "  📏 Width: \(String(format: "%.2f", dimensions.x))m\n"
      text += "  📏 Height: \(String(format: "%.2f", dimensions.y))m\n"
      text += "  📏 Thickness: \(String(format: "%.2f", dimensions.z))m\n\n"
    }
    
         // Floor area estimation (calculated from walls)
     if !room.walls.isEmpty {
       text += "🔲 FLOOR AREA (estimated)\n"
       text += "-" + String(repeating: "-", count: 30) + "\n"
       
       var minX: Float = Float.greatestFiniteMagnitude
       var maxX: Float = -Float.greatestFiniteMagnitude
       var minZ: Float = Float.greatestFiniteMagnitude
       var maxZ: Float = -Float.greatestFiniteMagnitude
       
       for wall in room.walls {
         let transform = wall.transform
         let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
         let dimensions = wall.dimensions
         
         minX = min(minX, position.x - dimensions.x/2)
         maxX = max(maxX, position.x + dimensions.x/2)
         minZ = min(minZ, position.z - dimensions.z/2)
         maxZ = max(maxZ, position.z + dimensions.z/2)
       }
       
       let floorArea = (maxX - minX) * (maxZ - minZ)
       text += "Estimated Floor Area: \(String(format: "%.2f", floorArea)) m²\n\n"
     }
    
    // Openings (doors, windows)
    if !room.openings.isEmpty {
      text += "🚪 OPENINGS (\(room.openings.count) detected)\n"
      text += "-" + String(repeating: "-", count: 30) + "\n"
      for (index, opening) in room.openings.enumerated() {
        let dimensions = opening.dimensions
        text += "Opening \(index + 1):\n"
        text += "  📏 Width: \(String(format: "%.2f", dimensions.x))m\n"
        text += "  📏 Height: \(String(format: "%.2f", dimensions.y))m\n"
        text += "  📏 Depth: \(String(format: "%.2f", dimensions.z))m\n\n"
      }
    }
    
    // Objects
    if !room.objects.isEmpty {
      text += "🪑 FURNITURE & OBJECTS (\(room.objects.count) detected)\n"
      text += "-" + String(repeating: "-", count: 40) + "\n"
      for (index, object) in room.objects.enumerated() {
        let dimensions = object.dimensions
        let categoryName = getCategoryName(object.category)
        let confidenceName = getConfidenceName(object.confidence)
        
        text += "\(index + 1). \(categoryName.uppercased())\n"
        text += "   📏 Width: \(String(format: "%.2f", dimensions.x))m\n"
        text += "   📏 Height: \(String(format: "%.2f", dimensions.y))m\n"
        text += "   📏 Depth: \(String(format: "%.2f", dimensions.z))m\n"
        text += "   🎯 Confidence: \(confidenceName)\n\n"
      }
    }
    
    return text
  }
  
  // Store temp preview URL for QuickLook
  private var tempPreviewURL: URL?
  
  @objc private func cancelPreview() {
    print("DEBUG: Cancelling preview...")
    dismiss(animated: true) {
      self.onScanComplete?(false, "Scan cancelled during preview", nil)
    }
  }
  
  @objc private func saveToFile() {
    // First check if we have raw room data to process
    if let roomData = latestCapturedRoomData {
      print("DEBUG: Processing room data for saving...")
      // Process the captured room data using RoomBuilder
      Task {
        do {
          let roomBuilder = RoomBuilder(options: [.beautifyObjects])
          let finalRoom = try await roomBuilder.capturedRoom(from: roomData)
          await MainActor.run {
            print("DEBUG: Room processing complete, saving internally...")
            self.saveRoomInternally(finalRoom)
          }
        } catch {
          print("DEBUG: ❌ Failed to process room data: \(error)")
          await MainActor.run {
            self.dismiss(animated: true) {
              self.onScanComplete?(false, "Failed to process scan: \(error.localizedDescription)", nil)
            }
          }
        }
      }
    } else if let room = latestCapturedRoom {
      print("DEBUG: Using existing room data for saving...")
      saveRoomInternally(room)
    } else {
      print("DEBUG: No room data to save")
      return
    }
  }
  
  private func saveRoomInternally(_ room: CapturedRoom) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let roomScansDirectory = documentsPath.appendingPathComponent("RoomScans")
    
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: roomScansDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: roomScansDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("DEBUG: Failed to create directory: \(error)")
      }
    }
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let fileName = "room_scan_\(timestamp).usdz"
    let fileURL = roomScansDirectory.appendingPathComponent(fileName)
    
    do {
      print("DEBUG: Saving room internally to: \(fileURL.path)")
      try room.export(to: fileURL)
      print("DEBUG: ✅ USDZ saved internally!")
      
             dismiss(animated: true) {
         self.onScanComplete?(true, "Room scan saved successfully! Found \(room.objects.count) objects, \(room.walls.count) walls, \(room.openings.count) openings.", fileURL.path)
       }
    } catch {
      print("DEBUG: ❌ USDZ save failed: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Failed to save scan: \(error.localizedDescription)", nil)
      }
    }
  }
  
  private func showFileSaveDialog(for room: CapturedRoom) {
    let timestamp = Int(Date().timeIntervalSince1970)
    let defaultFileName = "room_scan_\(timestamp).usdz"
    
    // Create a temporary USDZ file first
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempFileURL = tempDirectory.appendingPathComponent(defaultFileName)
    
    do {
      print("DEBUG: Creating temporary USDZ file...")
      try room.export(to: tempFileURL)
      print("DEBUG: ✅ Temporary USDZ file created")
      
      // Present document picker for saving
      if #available(iOS 14.0, *) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [tempFileURL], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        
        present(documentPicker, animated: true) {
          print("DEBUG: Document picker presented")
        }
      } else {
        // Fallback for iOS 13 - save to default location
        saveToDefaultLocation(room: room, fileName: defaultFileName)
      }
    } catch {
      print("DEBUG: ❌ Failed to create temporary USDZ file: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Failed to prepare file for saving: \(error.localizedDescription)", nil)
      }
    }
  }
  
  private func saveToDefaultLocation(room: CapturedRoom, fileName: String) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let roomScansDirectory = documentsPath.appendingPathComponent("RoomScans")
    
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: roomScansDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: roomScansDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("DEBUG: Failed to create directory: \(error)")
      }
    }
    
    let fileURL = roomScansDirectory.appendingPathComponent(fileName)
    
    do {
      print("DEBUG: Saving to default location: \(fileURL.path)")
      try room.export(to: fileURL)
      print("DEBUG: ✅ USDZ export successful!")
      
      dismiss(animated: true) {
        self.onScanComplete?(true, "Room scan saved successfully! Found \(room.objects.count) objects.", fileURL.path)
      }
    } catch {
      print("DEBUG: ❌ USDZ export failed: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Failed to save scan: \(error.localizedDescription)", nil)
      }
    }
  }
  
  // Store the most recent room data
  private var latestCapturedRoom: CapturedRoom?
  private var latestCapturedRoomData: CapturedRoomData?
}

// MARK: - RoomCaptureViewDelegate & RoomCaptureSessionDelegate

@available(iOS 16.0, *)
extension RoomScanViewController: RoomCaptureViewDelegate, RoomCaptureSessionDelegate, UIDocumentPickerDelegate, QLPreviewControllerDataSource {
  
  // MARK: - RoomCaptureViewDelegate Methods
  
  func captureView(_ view: RoomCaptureView, shouldPresent room: CapturedRoom) -> Bool {
    print("DEBUG: 🤔 shouldPresent called - room has \(room.objects.count) objects")
    // Return false to prevent automatic presentation - we'll handle the preview manually
    return false
  }
  
  func captureView(_ view: RoomCaptureView, didPresent room: CapturedRoom, error: Error?) {
    print("DEBUG: 🎉 Room capture completed! This means you successfully scanned a room!")
    
    if let error = error {
      print("DEBUG: Room capture error: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Scan failed: \(error.localizedDescription)", nil)
      }
      return
    }
    
    // This shouldn't be called since shouldPresent returns false
    print("DEBUG: Unexpected didPresent call")
  }
  
  // MARK: - RoomCaptureSessionDelegate Methods
  
  func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
    print("DEBUG: 📍 Room scanning started - objects: \(room.objects.count)")
    latestCapturedRoom = room
    logDetectedObjects(room)
  }
  
  func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
    print("DEBUG: 🔄 Room scan updated - objects: \(room.objects.count)")
    latestCapturedRoom = room
    logDetectedObjects(room)
  }
  
  func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
    print("DEBUG: ⚡ Room scan progress - objects: \(room.objects.count)")
    latestCapturedRoom = room
    if room.objects.count > 0 {
      logDetectedObjects(room)
    }
  }
  
  func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
    print("DEBUG: 🏁 Room capture session ended")
    if let error = error {
      print("DEBUG: ❌ Room capture session ended with error: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Scan failed: \(error.localizedDescription)", nil)
      }
    } else {
      print("DEBUG: ✅ Room capture session ended successfully")
      // Don't auto-process here - let the user decide in preview
      // Store the room data for later processing when user chooses to save
      self.latestCapturedRoomData = data
    }
  }
  
  private func logDetectedObjects(_ room: CapturedRoom) {
    for (index, object) in room.objects.enumerated() {
      let dimensions = object.dimensions
      let categoryName = getCategoryName(object.category)
      let confidenceName = getConfidenceName(object.confidence)
      
      // Log measurements in clear plain text format
      let width = String(format: "%.2f", dimensions.x)
      let height = String(format: "%.2f", dimensions.y)
      let depth = String(format: "%.2f", dimensions.z)
      
      print("DEBUG:   Object \(index + 1): \(categoryName.uppercased())")
      print("DEBUG:     📏 Measurements: Width=\(width)m, Height=\(height)m, Depth=\(depth)m")
      print("DEBUG:     🎯 Detection Confidence: \(confidenceName)")
    }
  }
  
  private func getCategoryName(_ category: CapturedRoom.Object.Category) -> String {
    switch category {
    case .storage: return "storage"
    case .refrigerator: return "refrigerator"
    case .stove: return "stove"
    case .bed: return "bed"
    case .sink: return "sink"
    case .washerDryer: return "washerDryer"
    case .toilet: return "toilet"
    case .bathtub: return "bathtub"
    case .oven: return "oven"
    case .dishwasher: return "dishwasher"
    case .table: return "table"
    case .sofa: return "sofa"
    case .chair: return "chair"
    case .fireplace: return "fireplace"
    case .television: return "television"
    case .stairs: return "stairs"
    @unknown default: return "unknown"
    }
  }
  
  private func getConfidenceName(_ confidence: CapturedRoom.Confidence) -> String {
    switch confidence {
    case .high: return "high"
    case .medium: return "medium"
    case .low: return "low"
    @unknown default: return "unknown"
    }
  }
  
  private func processCapturedRoom(_ room: CapturedRoom) {
    print("DEBUG: 🎉 Processing captured room!")
    print("DEBUG: Room captured successfully, exporting to USDZ...")
    print("DEBUG: Room has \(room.objects.count) objects")
    
    // Log detected objects with measurements in plain text
    for (index, object) in room.objects.enumerated() {
      let dimensions = object.dimensions
      let categoryName = getCategoryName(object.category)
      let confidenceName = getConfidenceName(object.confidence)
      
      let width = String(format: "%.2f", dimensions.x)
      let height = String(format: "%.2f", dimensions.y)
      let depth = String(format: "%.2f", dimensions.z)
      
      print("DEBUG: Object \(index + 1): \(categoryName.uppercased())")
      print("DEBUG:   📏 Precise Measurements:")
      print("DEBUG:     Width: \(width) meters")
      print("DEBUG:     Height: \(height) meters") 
      print("DEBUG:     Depth: \(depth) meters")
      print("DEBUG:   🎯 Detection Confidence: \(confidenceName)")
      print("DEBUG:   ---")
    }
    
    // Save to USDZ file
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let roomScansDirectory = documentsPath.appendingPathComponent("RoomScans")
    
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: roomScansDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: roomScansDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("DEBUG: Failed to create directory: \(error)")
      }
    }
    
    let timestamp = Int(Date().timeIntervalSince1970)
    let fileName = "room_scan_\(timestamp).usdz"
    let fileURL = roomScansDirectory.appendingPathComponent(fileName)
    
    do {
      print("DEBUG: Exporting to: \(fileURL.path)")
      try room.export(to: fileURL)
      print("DEBUG: ✅ USDZ export successful!")
      
      dismiss(animated: true) {
        self.onScanComplete?(true, "Room scan saved successfully! Found \(room.objects.count) objects.", fileURL.path)
      }
    } catch {
      print("DEBUG: ❌ USDZ export failed: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Failed to save scan: \(error.localizedDescription)", nil)
      }
    }
  }
  
  func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
    print("DEBUG: 🗑️ Room removed from session")
  }
  
  func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
    print("DEBUG: 🚀 Room capture session started with configuration")
  }
  
  // MARK: - UIDocumentPickerDelegate Methods
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    print("DEBUG: 📁 Document picker completed with URLs: \(urls)")
    
    if let savedURL = urls.first {
      print("DEBUG: ✅ File saved to: \(savedURL.path)")
      dismiss(animated: true) {
        self.onScanComplete?(true, "Room scan saved successfully to your chosen location!", savedURL.path)
      }
    } else {
      print("DEBUG: ❌ No URL returned from document picker")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Save operation failed - no location selected", nil)
      }
    }
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    print("DEBUG: 📁 Document picker was cancelled")
    // Don't dismiss the preview - let user try again or cancel manually
    controller.dismiss(animated: true)
  }
  
  // MARK: - QLPreviewControllerDataSource Methods
  
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return tempPreviewURL != nil ? 1 : 0
  }
  
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return tempPreviewURL! as QLPreviewItem
  }
}
#endif

// MARK: - Saved USDZ File Viewer

class SavedUSDZViewController: UIViewController {
  var fileName: String?
  var fileURL: URL?
  var onClose: (() -> Void)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTabbedInterface()
  }
  
  private func setupTabbedInterface() {
    guard let fileName = fileName, let fileURL = fileURL else {
      dismiss(animated: true)
      return
    }
    
    view.backgroundColor = UIColor.systemBackground
    
    // Create tab bar controller
    let tabBarController = UITabBarController()
    tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
    
    // Create 3D Preview tab
    let previewViewController = createSaved3DPreviewViewController(for: fileURL)
    previewViewController.tabBarItem = UITabBarItem(title: "3D Preview", image: UIImage(systemName: "cube"), tag: 0)
    
    // Create File Info tab
    let infoViewController = createSavedFileInfoViewController(fileName: fileName, fileURL: fileURL)
    infoViewController.tabBarItem = UITabBarItem(title: "File Info", image: UIImage(systemName: "info.circle"), tag: 1)
    
    // Set up tab bar controller
    tabBarController.viewControllers = [previewViewController, infoViewController]
    tabBarController.selectedIndex = 0 // Start with 3D preview
    
    // Add tab bar controller as child
    addChild(tabBarController)
    view.addSubview(tabBarController.view)
    tabBarController.didMove(toParent: self)
    
    // Set up constraints for tab bar controller (leave space for close button)
    NSLayoutConstraint.activate([
      tabBarController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBarController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
    ])
    
    // Add Close button
    let closeButton = UIButton(type: .system)
    closeButton.setTitle("Close", for: .normal)
    closeButton.setTitleColor(.white, for: .normal)
    closeButton.backgroundColor = UIColor.systemBlue
    closeButton.layer.cornerRadius = 8
    closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    
    view.addSubview(closeButton)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 100),
      closeButton.heightAnchor.constraint(equalToConstant: 44)
    ])
  }
  
  private func createSaved3DPreviewViewController(for fileURL: URL) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = UIColor.systemBackground
    
    #if canImport(QuickLook)
    if #available(iOS 12.0, *) {
      let previewController = QLPreviewController()
      previewController.dataSource = self
      
      // Add preview controller as child
      viewController.addChild(previewController)
      viewController.view.addSubview(previewController.view)
      previewController.view.frame = viewController.view.bounds
      previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      previewController.didMove(toParent: viewController)
    } else {
      addFallback3DMessage(to: viewController)
    }
    #else
    addFallback3DMessage(to: viewController)
    #endif
    
    return viewController
  }
  
  private func createSavedFileInfoViewController(fileName: String, fileURL: URL) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = UIColor.systemBackground
    
    // Create scroll view for file info
    let scrollView = UIScrollView()
    scrollView.backgroundColor = UIColor.systemBackground
    viewController.view.addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    
    // Create content view
    let contentView = UIView()
    scrollView.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    
    // Create file info text
    let fileInfoLabel = UILabel()
    fileInfoLabel.numberOfLines = 0
    fileInfoLabel.textColor = UIColor.label
    fileInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    fileInfoLabel.textAlignment = .left
    
    var infoText = generateSavedFileInfo(fileName: fileName, fileURL: fileURL)
    fileInfoLabel.text = infoText
    
    contentView.addSubview(fileInfoLabel)
    fileInfoLabel.translatesAutoresizingMaskIntoConstraints = false
    
    // Set up constraints
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
      
      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      
      fileInfoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
      fileInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      fileInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      fileInfoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
    ])
    
    return viewController
  }
  
  private func generateSavedFileInfo(fileName: String, fileURL: URL) -> String {
    var text = "📁 SAVED ROOM SCAN\n"
    text += "=" + String(repeating: "=", count: 25) + "\n\n"
    
    text += "📝 FILE INFORMATION\n"
    text += "-" + String(repeating: "-", count: 20) + "\n"
    text += "File Name: \(fileName)\n"
    
    // Get file size
    do {
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      if let fileSize = fileAttributes[.size] as? Int64 {
        let sizeInMB = Double(fileSize) / (1024 * 1024)
        text += "File Size: \(String(format: "%.1f", sizeInMB)) MB\n"
      }
      
      // Get creation date
      if let creationDate = fileAttributes[.creationDate] as? Date {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        text += "Created: \(formatter.string(from: creationDate))\n"
      }
    } catch {
      text += "File Size: Unable to determine\n"
    }
    
    text += "Format: USDZ (Universal Scene Description)\n\n"
    
    text += "🏠 ABOUT THIS SCAN\n"
    text += "-" + String(repeating: "-", count: 20) + "\n"
    text += "This is a 3D room scan captured using RoomPlan.\n\n"
    text += "The USDZ file contains:\n"
    text += "• 3D geometry of the scanned room\n"
    text += "• Detected objects and furniture\n"
    text += "• Wall and surface information\n"
    text += "• Spatial measurements and positioning\n\n"
    
    text += "📱 VIEWING OPTIONS\n"
    text += "-" + String(repeating: "-", count: 20) + "\n"
    text += "• 3D Preview: Interactive 3D model with AR view\n"
    text += "• File Info: This detailed information view\n\n"
    
    text += "💡 TIP\n"
    text += "-" + String(repeating: "-", count: 5) + "\n"
    text += "Switch to the '3D Preview' tab to explore the room in augmented reality. You can rotate, zoom, and view the scan from different angles.\n\n"
    
    text += "The original measurement data was captured during scanning and is embedded in the 3D model."
    
    return text
  }
  
  private func addFallback3DMessage(to viewController: UIViewController) {
    let label = UILabel()
    label.text = "3D Preview unavailable\nUSDZ file saved successfully!"
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = UIColor.secondaryLabel
    viewController.view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
    ])
  }
  
  @objc private func closeButtonTapped() {
    dismiss(animated: true) {
      self.onClose?()
    }
  }
}

// MARK: - SavedUSDZViewController QuickLook Support

#if canImport(QuickLook)
@available(iOS 12.0, *)
extension SavedUSDZViewController: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return fileURL != nil ? 1 : 0
  }
  
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return fileURL! as QLPreviewItem
  }
}
#endif