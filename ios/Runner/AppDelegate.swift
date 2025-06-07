import Flutter
import UIKit

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
    case "getSavedUSDZFiles":
      getSavedUSDZFiles(result: result)
    case "openUSDZFile":
      openUSDZFile(call: call, result: result)
    case "deleteUSDZFile":
      deleteUSDZFile(call: call, result: result)
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
        if success {
          result(["success": true, "message": message, "filePath": filePath ?? ""])
        } else {
          result(FlutterError(code: "SCAN_FAILED", message: message, details: nil))
        }
      }
      
      if let viewController = UIApplication.shared.keyWindow?.rootViewController {
        viewController.present(roomScanViewController, animated: true)
        result(["success": true, "message": "Room scan started", "scanning": true])
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
      #if canImport(QuickLook)
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
      #else
      result(FlutterError(code: "QUICKLOOK_NOT_AVAILABLE", 
                        message: "QuickLook framework not available", 
                        details: nil))
      #endif
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
    
    // The delegate method will handle the rest
  }
}

// MARK: - RoomCaptureViewDelegate & RoomCaptureSessionDelegate

@available(iOS 16.0, *)
extension RoomScanViewController: RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
  func captureView(_ view: RoomCaptureView, didPresent room: CapturedRoom, error: Error?) {
    print("DEBUG: Room capture completed!")
    
    if let error = error {
      print("DEBUG: Room capture error: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Scan failed: \(error.localizedDescription)", nil)
      }
      return
    }
    
    print("DEBUG: Room captured successfully, exporting to USDZ...")
    
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
        self.onScanComplete?(true, "Room scan saved successfully!", fileURL.path)
      }
    } catch {
      print("DEBUG: ❌ USDZ export failed: \(error)")
      dismiss(animated: true) {
        self.onScanComplete?(false, "Failed to save scan: \(error.localizedDescription)", nil)
      }
    }
  }
}
#endif

// MARK: - AR Quick Look Controller

#if canImport(QuickLook)
@available(iOS 12.0, *)
class ARQuickLookViewController: UIViewController {
  var fileURL: URL?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let fileURL = fileURL else {
      dismiss(animated: true)
      return
    }
    
    let previewController = QLPreviewController()
    previewController.dataSource = self
    previewController.delegate = self
    
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
#endif