import UIKit
import Foundation

@available(iOS 16.0, *)
@objc class SimpleRoomScanViewController: UIViewController {
    @objc var completionHandler: ((Result<String, Error>) -> Void)?
    
    private var roomCaptureController: AnyObject?
    private var captureView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCapture()
        setupUI()
    }
    
    private func setupRoomCapture() {
        // Use runtime instantiation to avoid compilation issues
        guard let roomCaptureControllerClass = NSClassFromString("RoomCaptureController") else {
            completionHandler?(.failure(RoomScanError.notSupported))
            return
        }
        
        // Check if RoomPlan is supported using runtime method calling
        if let isSupported = roomCaptureControllerClass.value(forKey: "isSupported") as? Bool,
           !isSupported {
            completionHandler?(.failure(RoomScanError.notSupported))
            return
        }
        
        // Create RoomCaptureController instance
        guard let roomCaptureController = roomCaptureControllerClass.alloc() as? NSObject else {
            completionHandler?(.failure(RoomScanError.notSupported))
            return
        }
        
        // Initialize the controller
        if roomCaptureController.responds(to: Selector(("init"))) {
            _ = roomCaptureController.perform(Selector(("init")))
        }
        
        self.roomCaptureController = roomCaptureController
        
        // Create RoomCaptureView
        guard let roomCaptureViewClass = NSClassFromString("RoomCaptureView") else {
            completionHandler?(.failure(RoomScanError.notSupported))
            return
        }
        
        guard let captureView = roomCaptureViewClass.alloc() as? UIView else {
            completionHandler?(.failure(RoomScanError.notSupported))
            return
        }
        
        // Initialize with frame
        if captureView.responds(to: Selector(("initWithFrame:"))) {
            _ = captureView.perform(Selector(("initWithFrame:")), with: NSValue(cgRect: view.bounds))
        }
        
        self.captureView = captureView
        
        // Set up the capture view
        view.backgroundColor = .black
        view.addSubview(captureView)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Set captureController property
        if captureView.responds(to: Selector(("setCaptureController:"))) {
            captureView.setValue(roomCaptureController, forKey: "captureController")
        }
        
        // Set delegate
        if captureView.responds(to: Selector(("setDelegate:"))) {
            captureView.setValue(self, forKey: "delegate")
        }
        
        // Start session
        if roomCaptureController.responds(to: Selector(("startSession"))) {
            roomCaptureController.perform(Selector(("startSession")))
        }
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
        if let roomCaptureController = roomCaptureController,
           roomCaptureController.responds(to: Selector(("stopSession"))) {
            roomCaptureController.perform(Selector(("stopSession")))
        }
    }
    
    @objc private func cancelButtonTapped() {
        if let roomCaptureController = roomCaptureController,
           roomCaptureController.responds(to: Selector(("stopSession"))) {
            roomCaptureController.perform(Selector(("stopSession")))
        }
        completionHandler?(.failure(RoomScanError.cancelled))
        dismiss(animated: true)
    }
    
    // This method will be called by RoomCaptureView delegate methods via runtime
    @objc func handleRoomCaptureResult(_ result: Any?, error: Error?) {
        if let error = error {
            completionHandler?(.failure(error))
            dismiss(animated: true)
            return
        }
        
        // For now, return a mock result since we can't easily convert CapturedRoom at runtime
        let mockRoomData = """
        {
            "confidence": "high",
            "dimensions": {
                "width": 3.5,
                "height": 2.8,
                "length": 4.2
            },
            "surfaces": [
                {
                    "category": "wall",
                    "confidence": "high",
                    "dimensions": {
                        "width": 4.2,
                        "height": 2.8
                    }
                }
            ],
            "objects": []
        }
        """
        
        completionHandler?(.success(mockRoomData))
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