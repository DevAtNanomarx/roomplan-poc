import Foundation
import Flutter
#if canImport(RoomPlan)
import RoomPlan
import ARKit
#endif

#if canImport(RoomPlan)
class RoomPlanHandler {
    static let shared = RoomPlanHandler()
    
    @available(iOS 16.0, *)
    private var roomCaptureController: RoomCaptureController?
    @available(iOS 16.0, *)
    private var captureView: RoomCaptureView?
    private var currentResult: FlutterResult?
    private var parentController: FlutterViewController?
    
    private init() {
    }
    
    func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult, controller: FlutterViewController) {
        if #available(iOS 16.0, *) {
            self.parentController = controller
            
            switch call.method {
            case "isRoomPlanSupported":
                checkRoomPlanSupport(result: result)
            case "startRoomScan":
                startRoomScan(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        } else {
            // Handle unsupported iOS versions
            switch call.method {
            case "isRoomPlanSupported":
                result(false)
            case "startRoomScan":
                result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                                  message: "RoomPlan requires iOS 16.0 or later", 
                                  details: nil))
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func checkRoomPlanSupport(result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(false)
            return
        }
        
        let isSupported = RoomCaptureController.isSupported
        result(isSupported)
    }
    
    private func startRoomScan(result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", 
                              message: "RoomPlan requires iOS 16.0 or later", 
                              details: nil))
            return
        }
        
        guard RoomCaptureController.isSupported else {
            result(FlutterError(code: "DEVICE_NOT_SUPPORTED", 
                              message: "RoomPlan is not supported on this device", 
                              details: nil))
            return
        }
        
        self.currentResult = result
        
        DispatchQueue.main.async {
            self.presentRoomCaptureView()
        }
    }
    
    @available(iOS 16.0, *)
    private func presentRoomCaptureView() {
        guard let parentController = self.parentController else { return }
        
        let roomCaptureController = RoomCaptureController()
        self.roomCaptureController = roomCaptureController
        
        let captureView = RoomCaptureView(frame: parentController.view.bounds)
        captureView.captureController = roomCaptureController
        captureView.delegate = self
        self.captureView = captureView
        
        let scanViewController = RoomScanViewController()
        scanViewController.captureView = captureView
        scanViewController.roomPlanHandler = self
        
        parentController.present(scanViewController, animated: true)
        
        roomCaptureController.startSession()
    }
    
    func finishScan() {
        guard let roomCaptureController = self.roomCaptureController else { return }
        roomCaptureController.stopSession()
    }
    
    func cancelScan() {
        guard let roomCaptureController = self.roomCaptureController else { return }
        roomCaptureController.stopSession()
        
        if let result = currentResult {
            result(FlutterError(code: "SCAN_CANCELLED", 
                              message: "Room scan was cancelled by user", 
                              details: nil))
            currentResult = nil
        }
        
        parentController?.dismiss(animated: true)
    }
}

@available(iOS 16.0, *)
extension RoomPlanHandler: RoomCaptureViewDelegate {
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            if let result = currentResult {
                result(FlutterError(code: "SCAN_ERROR", 
                                  message: "Room scan failed: \(error.localizedDescription)", 
                                  details: nil))
                currentResult = nil
            }
            parentController?.dismiss(animated: true)
            return
        }
        
        guard let capturedRoom = processedResult as CapturedRoom? else {
            if let result = currentResult {
                result(FlutterError(code: "PROCESSING_ERROR", 
                                  message: "Failed to process room data", 
                                  details: nil))
                currentResult = nil
            }
            parentController?.dismiss(animated: true)
            return
        }
        
        let roomData = convertCapturedRoomToJSON(capturedRoom: capturedRoom)
        
        if let result = currentResult {
            result(roomData)
            currentResult = nil
        }
        
        parentController?.dismiss(animated: true)
    }
    
    private func convertCapturedRoomToJSON(capturedRoom: CapturedRoom) -> String {
        var roomDict: [String: Any] = [:]
        
        // Room confidence
        roomDict["confidence"] = capturedRoom.confidence.description
        
        // Room dimensions
        let dimensions = capturedRoom.dimensions
        roomDict["dimensions"] = [
            "width": dimensions.width,
            "height": dimensions.height,
            "length": dimensions.length
        ]
        
        // Surfaces
        var surfacesArray: [[String: Any]] = []
        for surface in capturedRoom.surfaces {
            var surfaceDict: [String: Any] = [:]
            surfaceDict["category"] = surface.category.description
            surfaceDict["confidence"] = surface.confidence.description
            
            // Surface dimensions
            let surfaceDimensions = surface.dimensions
            surfaceDict["dimensions"] = [
                "width": surfaceDimensions.width,
                "height": surfaceDimensions.height
            ]
            
            // Surface transform (position and orientation)
            let transform = surface.transform
            surfaceDict["transform"] = [
                "translation": [
                    "x": transform.columns.3.x,
                    "y": transform.columns.3.y,
                    "z": transform.columns.3.z
                ],
                "rotation": [
                    "m00": transform.columns.0.x, "m01": transform.columns.1.x, "m02": transform.columns.2.x,
                    "m10": transform.columns.0.y, "m11": transform.columns.1.y, "m12": transform.columns.2.y,
                    "m20": transform.columns.0.z, "m21": transform.columns.1.z, "m22": transform.columns.2.z
                ]
            ]
            
            surfacesArray.append(surfaceDict)
        }
        roomDict["surfaces"] = surfacesArray
        
        // Objects
        var objectsArray: [[String: Any]] = []
        for object in capturedRoom.objects {
            var objectDict: [String: Any] = [:]
            objectDict["category"] = object.category.description
            objectDict["confidence"] = object.confidence.description
            
            // Object dimensions
            let objectDimensions = object.dimensions
            objectDict["dimensions"] = [
                "width": objectDimensions.width,
                "height": objectDimensions.height,
                "length": objectDimensions.length
            ]
            
            // Object transform
            let transform = object.transform
            objectDict["transform"] = [
                "translation": [
                    "x": transform.columns.3.x,
                    "y": transform.columns.3.y,
                    "z": transform.columns.3.z
                ],
                "rotation": [
                    "m00": transform.columns.0.x, "m01": transform.columns.1.x, "m02": transform.columns.2.x,
                    "m10": transform.columns.0.y, "m11": transform.columns.1.y, "m12": transform.columns.2.y,
                    "m20": transform.columns.0.z, "m21": transform.columns.1.z, "m22": transform.columns.2.z
                ]
            ]
            
            objectsArray.append(objectDict)
        }
        roomDict["objects"] = objectsArray
        
        // Convert to JSON string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: roomDict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error converting room data to JSON: \(error)")
            return "{}"
        }
    }
}

@available(iOS 16.0, *)
class RoomScanViewController: UIViewController {
    var captureView: RoomCaptureView?
    var roomPlanHandler: RoomPlanHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let captureView = captureView else { return }
        
        view.backgroundColor = .black
        view.addSubview(captureView)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        setupUI()
    }
    
    private func setupUI() {
        // Done button
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor.systemBlue
        doneButton.layer.cornerRadius = 8
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Instructions label
        let instructionsLabel = UILabel()
        instructionsLabel.text = "Move around the room to scan it with your device. Tap 'Done' when finished."
        instructionsLabel.textColor = .white
        instructionsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        instructionsLabel.layer.cornerRadius = 8
        instructionsLabel.clipsToBounds = true
        
        view.addSubview(doneButton)
        view.addSubview(cancelButton)
        view.addSubview(instructionsLabel)
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Instructions at top
            instructionsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Done button
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.widthAnchor.constraint(equalToConstant: 80),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Cancel button
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func doneButtonTapped() {
        roomPlanHandler?.finishScan()
    }
    
    @objc private func cancelButtonTapped() {
        roomPlanHandler?.cancelScan()
    }
}
#else
// Fallback class for when RoomPlan is not available
class RoomPlanHandler {
    static let shared = RoomPlanHandler()
    
    private init() {
    }
    
    func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult, controller: FlutterViewController) {
        switch call.method {
        case "isRoomPlanSupported":
            result(false)
        case "startRoomScan":
            result(FlutterError(code: "ROOMPLAN_NOT_AVAILABLE", 
                              message: "RoomPlan framework is not available", 
                              details: nil))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
#endif 