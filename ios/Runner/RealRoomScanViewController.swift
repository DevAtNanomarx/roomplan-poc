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
    private var progressView: UIProgressView!
    private var scanningTipsLabel: UILabel!
    private var surfaceCountLabel: UILabel!
    private var objectCountLabel: UILabel!
    
    // Scanning state tracking
    private var scanningStartTime: Date?
    private var lastStatusUpdate: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCapture()
        setupUI()
        scanningStartTime = Date()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        #if canImport(RoomPlan)
        roomCaptureController?.stopSession()
        #endif
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
        instructionsLabel.text = "🏠 Room Scan Instructions\n\n• Move slowly around the room\n• Point camera at all walls and corners\n• Capture floors, ceilings, and furniture\n• Keep device steady and upright"
        instructionsLabel.textColor = .white
        instructionsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        instructionsLabel.textAlignment = .left
        instructionsLabel.numberOfLines = 0
        instructionsLabel.layer.cornerRadius = 16
        instructionsLabel.clipsToBounds = true
        instructionsLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        instructionsLabel.layer.borderWidth = 1
        instructionsLabel.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        
        // Add padding to instructions label
        instructionsLabel.layer.sublayerTransform = CATransform3DMakeTranslation(16, 16, 0)
        
        // Scanning tips label (dynamic)
        scanningTipsLabel = UILabel()
        scanningTipsLabel.text = "💡 Tip: Start with corners and edges"
        scanningTipsLabel.textColor = .systemYellow
        scanningTipsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        scanningTipsLabel.textAlignment = .center
        scanningTipsLabel.numberOfLines = 2
        scanningTipsLabel.layer.cornerRadius = 8
        scanningTipsLabel.clipsToBounds = true
        scanningTipsLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "🔍 Initializing scan..."
        statusLabel.textColor = .systemBlue
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds = true
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        // Progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.progress = 0.0
        
        // Surface count label
        surfaceCountLabel = UILabel()
        surfaceCountLabel.text = "Surfaces: 0"
        surfaceCountLabel.textColor = .systemGreen
        surfaceCountLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        surfaceCountLabel.textAlignment = .center
        surfaceCountLabel.layer.cornerRadius = 8
        surfaceCountLabel.clipsToBounds = true
        surfaceCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        // Object count label
        objectCountLabel = UILabel()
        objectCountLabel.text = "Objects: 0"
        objectCountLabel.textColor = .systemPurple
        objectCountLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        objectCountLabel.textAlignment = .center
        objectCountLabel.layer.cornerRadius = 8
        objectCountLabel.clipsToBounds = true
        objectCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        // Done button
        doneButton = UIButton(type: .system)
        doneButton.setTitle("✓ Finish Scan", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor.systemGreen
        doneButton.layer.cornerRadius = 12
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        doneButton.layer.shadowColor = UIColor.black.cgColor
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        doneButton.layer.shadowRadius = 4
        doneButton.layer.shadowOpacity = 0.3
        
        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("✕ Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed
        cancelButton.layer.cornerRadius = 12
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.layer.shadowColor = UIColor.black.cgColor
        cancelButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        cancelButton.layer.shadowRadius = 4
        cancelButton.layer.shadowOpacity = 0.3
        
        // Add all UI elements
        view.addSubview(instructionsLabel)
        view.addSubview(scanningTipsLabel)
        view.addSubview(statusLabel)
        view.addSubview(progressView)
        view.addSubview(surfaceCountLabel)
        view.addSubview(objectCountLabel)
        view.addSubview(doneButton)
        view.addSubview(cancelButton)
        
        // Disable autoresizing masks
        [instructionsLabel, scanningTipsLabel, statusLabel, progressView, 
         surfaceCountLabel, objectCountLabel, doneButton, cancelButton].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Instructions at top
            instructionsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Scanning tips
            scanningTipsLabel.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 12),
            scanningTipsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scanningTipsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scanningTipsLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: scanningTipsLabel.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 180),
            statusLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Count labels
            surfaceCountLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            surfaceCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            surfaceCountLabel.widthAnchor.constraint(equalToConstant: 100),
            surfaceCountLabel.heightAnchor.constraint(equalToConstant: 28),
            
            objectCountLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            objectCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            objectCountLabel.widthAnchor.constraint(equalToConstant: 100),
            objectCountLabel.heightAnchor.constraint(equalToConstant: 28),
            
            // Done button
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            doneButton.widthAnchor.constraint(equalToConstant: 120),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Cancel button
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Start periodic updates
        startPeriodicUpdates()
    }
    
    private func startPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self, self.view.window != nil else {
                timer.invalidate()
                return
            }
            self.updateScanningTips()
            self.updateProgress()
        }
    }
    
    private func updateScanningTips() {
        let tips = [
            "💡 Tip: Move slowly for better accuracy",
            "🎯 Tip: Focus on room corners and edges", 
            "📱 Tip: Keep device vertical and steady",
            "🪑 Tip: Scan furniture from multiple angles",
            "🚪 Tip: Don't forget doors and windows",
            "⏰ Tip: Take your time for best results"
        ]
        
        let randomTip = tips.randomElement() ?? tips[0]
        
        DispatchQueue.main.async {
            UIView.transition(with: self.scanningTipsLabel, duration: 0.3, options: .transitionCrossDissolve) {
                self.scanningTipsLabel.text = randomTip
            }
        }
    }
    
    private func updateProgress() {
        guard let startTime = scanningStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let estimatedTotalTime: TimeInterval = 60 // 60 seconds estimated
        let progress = min(Float(elapsed / estimatedTotalTime), 0.9) // Cap at 90% until done
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.progressView.progress = progress
            }
        }
    }
    
    @objc private func doneButtonTapped() {
        statusLabel.text = "⚙️ Processing scan..."
        statusLabel.textColor = .systemOrange
        progressView.progress = 1.0
        doneButton.isEnabled = false
        cancelButton.isEnabled = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        #if canImport(RoomPlan)
        roomCaptureController?.stopSession()
        #endif
    }
    
    @objc private func cancelButtonTapped() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
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
            DispatchQueue.main.async {
                self.statusLabel.text = "❌ Scan Error"
                self.statusLabel.textColor = .systemRed
            }
            return false
        }
        
        DispatchQueue.main.async {
            self.statusLabel.text = "⚙️ Processing data..."
            self.statusLabel.textColor = .systemOrange
            self.progressView.progress = 0.95
        }
        
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        DispatchQueue.main.async {
            self.statusLabel.text = "✅ Scan Complete!"
            self.statusLabel.textColor = .systemGreen
            self.progressView.progress = 1.0
            
            // Update final counts
            self.surfaceCountLabel.text = "Surfaces: \(processedResult.surfaces.count)"
            self.objectCountLabel.text = "Objects: \(processedResult.objects.count)"
            
            // Add success haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.statusLabel.text = "❌ Processing Failed"
                self.statusLabel.textColor = .systemRed
                
                // Add error haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                self.completionHandler?(.failure(error))
                
                // Delay dismissal to show error state
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss(animated: true)
                }
            }
            return
        }
        
        let roomData = convertCapturedRoomToJSON(capturedRoom: processedResult)
        
        DispatchQueue.main.async {
            // Show success state briefly before dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.completionHandler?(.success(roomData))
                self.dismiss(animated: true)
            }
        }
    }
    
    // Add method to track scanning progress in real-time
    func captureView(_ captureView: RoomCaptureView, didUpdate room: CapturedRoom?) {
        guard let room = room else { return }
        
        DispatchQueue.main.async {
            // Update real-time counts
            self.surfaceCountLabel.text = "Surfaces: \(room.surfaces.count)"
            self.objectCountLabel.text = "Objects: \(room.objects.count)"
            
            // Update status based on scan quality
            let confidence = room.confidence
            switch confidence {
            case .high:
                self.statusLabel.text = "🟢 High Quality"
                self.statusLabel.textColor = .systemGreen
            case .medium:
                self.statusLabel.text = "🟡 Medium Quality"
                self.statusLabel.textColor = .systemOrange
            case .low:
                self.statusLabel.text = "🔴 Low Quality - Keep Scanning"
                self.statusLabel.textColor = .systemRed
            @unknown default:
                self.statusLabel.text = "🔍 Scanning..."
                self.statusLabel.textColor = .systemBlue
            }
            
            // Enable done button only when we have reasonable data
            let hasMinimumData = room.surfaces.count >= 3 && confidence != .low
            self.doneButton.isEnabled = hasMinimumData
            self.doneButton.alpha = hasMinimumData ? 1.0 : 0.6
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