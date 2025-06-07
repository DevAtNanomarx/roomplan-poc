import Foundation
import UIKit
import Flutter

@available(iOS 16.0, *)
class RoomPlanManager: NSObject {
    static let shared = RoomPlanManager()
    
    private var currentResult: FlutterResult?
    private var parentController: UIViewController?
    
    private override init() {
        super.init()
    }
    
    func checkSupport() -> Bool {
        // Use runtime checking to avoid compilation issues
        guard let roomCaptureControllerClass = NSClassFromString("RoomCaptureController") else {
            return false
        }
        
        // Use KVC to call isSupported property
        if let isSupported = roomCaptureControllerClass.value(forKey: "isSupported") as? Bool {
            return isSupported
        }
        
        return false
    }
    
    func startScan(from controller: UIViewController, result: @escaping FlutterResult) {
        guard checkSupport() else {
            result(FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                              message: "RoomPlan is not supported on this device. Requires LiDAR sensor.", 
                              details: nil))
            return
        }
        
        self.currentResult = result
        self.parentController = controller
        
        // Create the scan view controller
        let scanViewController = SimpleRoomScanViewController()
        
        // Set up completion handler
        scanViewController.completionHandler = { [weak self] scanResult in
            guard let self = self else { return }
            
            switch scanResult {
            case .success(let roomData):
                self.saveRoomData(roomData)
            case .failure(let error):
                self.currentResult?(FlutterError(code: "SCAN_ERROR", 
                                               message: "Room scan failed: \(error.localizedDescription)", 
                                               details: nil))
                self.currentResult = nil
            }
        }
        
        DispatchQueue.main.async {
            controller.present(scanViewController, animated: true)
        }
    }
    
    private func saveRoomData(_ roomData: String) {
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
            
            currentResult?(jsonString)
            currentResult = nil
        } catch {
            currentResult?(FlutterError(code: "SAVE_ERROR", 
                                      message: "Failed to save room data: \(error.localizedDescription)", 
                                      details: nil))
            currentResult = nil
        }
    }
}

// Fallback for iOS versions below 16.0
class RoomPlanManagerFallback: NSObject {
    static let shared = RoomPlanManagerFallback()
    
    private override init() {
        super.init()
    }
    
    func checkSupport() -> Bool {
        return false
    }
    
    func startScan(from controller: UIViewController, result: @escaping FlutterResult) {
        result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                          message: "RoomPlan requires iOS 16.0 or later", 
                          details: nil))
    }
} 