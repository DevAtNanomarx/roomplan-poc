import UIKit
import Foundation
#if canImport(RoomPlan)
import RoomPlan
import ARKit
#endif

@available(iOS 16.0, *)
class RealRoomScanViewController: UIViewController {
    var completionHandler: ((Result<String, Error>) -> Void)?
    
    #if canImport(RoomPlan)
    private var roomCaptureController: RoomCaptureController?
    private var captureView: RoomCaptureView?
    #endif
    
    private var instructionsLabel: UILabel!
    private var doneButton: UIButton!
    private var cancelButton: UIButton!
    private var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCapture()
        setupUI()
    }
    
    private func setupRoomCapture() {
        #if canImport(RoomPlan)
        guard RoomCaptureController.isSupported else {
            completionHandler?(.failure(RoomScanError.notSupported))
            return
        }
        
        roomCaptureController = RoomCaptureController()
        
        let captureView = RoomCaptureView(frame: view.bounds)
        captureView.captureController = roomCaptureController
        captureView.delegate = self
        self.captureView = captureView
        
        view.backgroundColor = .black
        view.addSubview(captureView)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        roomCaptureController?.startSession()
        #else
        completionHandler?(.failure(RoomScanError.notSupported))
        #endif
    }
    
    private func setupUI() {
        // Instructions label
        instructionsLabel = UILabel()
        instructionsLabel.text = "Move around the room to scan it with your device.\nPoint your camera at walls, floors, and furniture.\nTap 'Done' when you've captured the entire room."
        instructionsLabel.textColor = .white
        instructionsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        instructionsLabel.layer.cornerRadius = 12
        instructionsLabel.clipsToBounds = true
        instructionsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionsLabel.layer.borderWidth = 1
        instructionsLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "Scanning..."
        statusLabel.textColor = .systemBlue
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds = true
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        // Done button
        doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor.systemBlue
        doneButton.layer.cornerRadius = 12
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        doneButton.layer.shadowColor = UIColor.black.cgColor
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        doneButton.layer.shadowRadius = 4
        doneButton.layer.shadowOpacity = 0.3
        
        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed
        cancelButton.layer.cornerRadius = 12
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.layer.shadowColor = UIColor.black.cgColor
        cancelButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        cancelButton.layer.shadowRadius = 4
        cancelButton.layer.shadowOpacity = 0.3
        
        view.addSubview(instructionsLabel)
        view.addSubview(statusLabel)
        view.addSubview(doneButton)
        view.addSubview(cancelButton)
        
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Instructions at top
            instructionsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 120),
            statusLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // Done button
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            doneButton.widthAnchor.constraint(equalToConstant: 100),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel button
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func doneButtonTapped() {
        statusLabel.text = "Processing..."
        statusLabel.textColor = .systemOrange
        doneButton.isEnabled = false
        cancelButton.isEnabled = false
        
        #if canImport(RoomPlan)
        roomCaptureController?.stopSession()
        #endif
    }
    
    @objc private func cancelButtonTapped() {
        #if canImport(RoomPlan)
        roomCaptureController?.stopSession()
        #endif
        completionHandler?(.failure(RoomScanError.cancelled))
        dismiss(animated: true)
    }
    
    #if canImport(RoomPlan)
    private func convertCapturedRoomToJSON(capturedRoom: CapturedRoom) -> String {
        var roomDict: [String: Any] = [:]
        
        // Basic room information
        roomDict["confidence"] = capturedRoom.confidence.description
        roomDict["scanTimestamp"] = Int(Date().timeIntervalSince1970)
        
        // Room dimensions
        let dimensions = capturedRoom.dimensions
        roomDict["dimensions"] = [
            "width": Double(dimensions.width),
            "height": Double(dimensions.height), 
            "length": Double(dimensions.length)
        ]
        
        // Calculate room area and volume
        let area = Double(dimensions.width * dimensions.length)
        let volume = Double(dimensions.width * dimensions.length * dimensions.height)
        roomDict["area"] = area
        roomDict["volume"] = volume
        
        // Surfaces
        var surfacesArray: [[String: Any]] = []
        for (index, surface) in capturedRoom.surfaces.enumerated() {
            var surfaceDict: [String: Any] = [:]
            surfaceDict["id"] = index
            surfaceDict["category"] = surface.category.description
            surfaceDict["confidence"] = surface.confidence.description
            
            // Surface dimensions
            let surfaceDimensions = surface.dimensions
            surfaceDict["dimensions"] = [
                "width": Double(surfaceDimensions.width),
                "height": Double(surfaceDimensions.height)
            ]
            
            // Surface area
            let surfaceArea = Double(surfaceDimensions.width * surfaceDimensions.height)
            surfaceDict["area"] = surfaceArea
            
            // Surface transform (position and orientation)
            let transform = surface.transform
            surfaceDict["transform"] = [
                "translation": [
                    "x": Double(transform.columns.3.x),
                    "y": Double(transform.columns.3.y),
                    "z": Double(transform.columns.3.z)
                ],
                "rotation": [
                    "m00": Double(transform.columns.0.x), "m01": Double(transform.columns.1.x), "m02": Double(transform.columns.2.x),
                    "m10": Double(transform.columns.0.y), "m11": Double(transform.columns.1.y), "m12": Double(transform.columns.2.y),
                    "m20": Double(transform.columns.0.z), "m21": Double(transform.columns.1.z), "m22": Double(transform.columns.2.z)
                ]
            ]
            
            surfacesArray.append(surfaceDict)
        }
        roomDict["surfaces"] = surfacesArray
        
        // Objects
        var objectsArray: [[String: Any]] = []
        for (index, object) in capturedRoom.objects.enumerated() {
            var objectDict: [String: Any] = [:]
            objectDict["id"] = index
            objectDict["category"] = object.category.description
            objectDict["confidence"] = object.confidence.description
            
            // Object dimensions
            let objectDimensions = object.dimensions
            objectDict["dimensions"] = [
                "width": Double(objectDimensions.width),
                "height": Double(objectDimensions.height),
                "length": Double(objectDimensions.length)
            ]
            
            // Object volume
            let objectVolume = Double(objectDimensions.width * objectDimensions.height * objectDimensions.length)
            objectDict["volume"] = objectVolume
            
            // Object transform
            let transform = object.transform
            objectDict["transform"] = [
                "translation": [
                    "x": Double(transform.columns.3.x),
                    "y": Double(transform.columns.3.y),
                    "z": Double(transform.columns.3.z)
                ],
                "rotation": [
                    "m00": Double(transform.columns.0.x), "m01": Double(transform.columns.1.x), "m02": Double(transform.columns.2.x),
                    "m10": Double(transform.columns.0.y), "m11": Double(transform.columns.1.y), "m12": Double(transform.columns.2.y),
                    "m20": Double(transform.columns.0.z), "m21": Double(transform.columns.1.z), "m22": Double(transform.columns.2.z)
                ]
            ]
            
            objectsArray.append(objectDict)
        }
        roomDict["objects"] = objectsArray
        
        // Summary statistics
        roomDict["summary"] = [
            "totalSurfaces": surfacesArray.count,
            "totalObjects": objectsArray.count,
            "roomType": inferRoomType(from: objectsArray),
            "scanQuality": capturedRoom.confidence.description
        ]
        
        // Convert to JSON string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: roomDict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error converting room data to JSON: \(error)")
            return "{}"
        }
    }
    
    private func inferRoomType(from objects: [[String: Any]]) -> String {
        let objectCategories = objects.compactMap { $0["category"] as? String }
        
        if objectCategories.contains("bed") {
            return "bedroom"
        } else if objectCategories.contains("stove") || objectCategories.contains("refrigerator") {
            return "kitchen"
        } else if objectCategories.contains("toilet") || objectCategories.contains("bathtub") {
            return "bathroom"
        } else if objectCategories.contains("sofa") || objectCategories.contains("television") {
            return "living_room"
        } else if objectCategories.contains("table") && objectCategories.contains("chair") {
            return "dining_room"
        } else {
            return "unknown"
        }
    }
    #endif
}

#if canImport(RoomPlan)
@available(iOS 16.0, *)
extension RealRoomScanViewController: RoomCaptureViewDelegate {
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error = error {
            print("Error during room capture: \(error)")
            return false
        }
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Complete!"
            self.statusLabel.textColor = .systemGreen
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
                self.dismiss(animated: true)
            }
            return
        }
        
        let roomData = convertCapturedRoomToJSON(capturedRoom: processedResult)
        
        DispatchQueue.main.async {
            self.completionHandler?(.success(roomData))
            self.dismiss(animated: true)
        }
    }
}
#endif

enum RoomScanError: Error {
    case notSupported
    case cancelled
    case processingFailed
    
    var localizedDescription: String {
        switch self {
        case .notSupported:
            return "RoomPlan is not supported on this device"
        case .cancelled:
            return "Room scan was cancelled by user"
        case .processingFailed:
            return "Failed to process room scan data"
        }
    }
} 