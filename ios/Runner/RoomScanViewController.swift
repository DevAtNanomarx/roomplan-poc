import UIKit
#if canImport(RoomPlan)
import RoomPlan
import ARKit

@available(iOS 16.0, *)
class RoomScanViewController: UIViewController {
    var completionHandler: ((Result<String, Error>) -> Void)?
    
    private var roomCaptureController: RoomCaptureController?
    private var captureView: RoomCaptureView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCapture()
        setupUI()
    }
    
    private func setupRoomCapture() {
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
            captureView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        roomCaptureController?.startSession()
    }
    
    private func setupUI() {
        // Done button
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor.systemBlue
        doneButton.layer.cornerRadius = 8
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed
        cancelButton.layer.cornerRadius = 8
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
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
        instructionsLabel.font = UIFont.systemFont(ofSize: 14)
        
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
        roomCaptureController?.stopSession()
    }
    
    @objc private func cancelButtonTapped() {
        roomCaptureController?.stopSession()
        completionHandler?(.failure(RoomScanError.cancelled))
        dismiss(animated: true)
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
extension RoomScanViewController: RoomCaptureViewDelegate {
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            completionHandler?(.failure(error))
            dismiss(animated: true)
            return
        }
        
        let roomData = convertCapturedRoomToJSON(capturedRoom: processedResult)
        completionHandler?(.success(roomData))
        dismiss(animated: true)
    }
}

enum RoomScanError: Error {
    case notSupported
    case cancelled
    
    var localizedDescription: String {
        switch self {
        case .notSupported:
            return "RoomPlan is not supported on this device"
        case .cancelled:
            return "Room scan was cancelled by user"
        }
    }
}

#else
// Fallback for when RoomPlan is not available
class RoomScanViewController: UIViewController {
    var completionHandler: ((Result<String, Error>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        completionHandler?(.failure(RoomScanError.notSupported))
        dismiss(animated: true)
    }
}

enum RoomScanError: Error {
    case notSupported
    case cancelled
    
    var localizedDescription: String {
        switch self {
        case .notSupported:
            return "RoomPlan is not supported on this device"
        case .cancelled:
            return "Room scan was cancelled by user"
        }
    }
}
#endif 