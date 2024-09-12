//
//  CameraView.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 09/09/24.
//

import UIKit
import MediaPipeTasksVision

final class CameraView: UIView {
    
    private lazy var cameraFeedService = CameraFeedService(previewView: self)
    
    private let handLandmarkerServiceQueue = DispatchQueue(
        label: "com.wavinDev.cameraView.handLandmarkerServiceQueue",
        attributes: .concurrent)
    
    private let backgroundQueue = DispatchQueue(label: "com.wavinDev.cameraView.backgroundQueue")
    
    private let overlayView = OverlayView()
    
    private lazy var resumeButton: UIButton = {
        let button = UIButton()
        button.setTitle(String(localized: "Resume"), for: .normal)
        button.addTarget(self, action: #selector(didTapResume(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var cameraUnavailableLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = String(localized: "Camera Unavailable")
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        return label
    }()
    
    private var _handLandmarkerService: HandLandmarkerService?
    private var handLandmarkerService: HandLandmarkerService? {
        get {
            handLandmarkerServiceQueue.sync {
                return self._handLandmarkerService
            }
        }
        set {
            handLandmarkerServiceQueue.async(flags: .barrier) {
                self._handLandmarkerService = newValue
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cameraFeedService.updateVideoPreviewLayer(toFrame: bounds)
    }
    
    private func setup() {
        backgroundColor = .clear
        overlayView.backgroundColor = .clear
        
        cameraFeedService.delegate = self
        
        addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Start
extension CameraView {
    
    func start() {
        initializeHandLandmarkerServiceOnSessionResumption()
        cameraFeedService.startLiveCameraSession { [weak self] cameraConfiguration in
            DispatchQueue.main.async {
                switch cameraConfiguration {
                case .failed:
                    print("Failed")
                    //              self?.presentVideoConfigurationErrorAlert()
                case .permissionDenied:
                    print("Permission Denied")
                    //              self?.presentCameraPermissionsDeniedAlert()
                default:
                    break
                }
            }
        }
    }
    
    private func initializeHandLandmarkerServiceOnSessionResumption() {
        clearAndInitializeHandLandmarkerService()
    }
    
    private func clearAndInitializeHandLandmarkerService() {
        handLandmarkerService = nil
        handLandmarkerService = HandLandmarkerService.liveStreamHandLandmarkerService(
            modelPath: DefaultConstants.modelPath,
            numHands: DefaultConstants.numHands,
            minHandDetectionConfidence: DefaultConstants.minHandDetectionConfidence,
            minHandPresenceConfidence: DefaultConstants.minHandPresenceConfidence,
            minTrackingConfidence: DefaultConstants.minTrackingConfidence,
            liveStreamDelegate: self,
            delegate: DefaultConstants.delegate
        )
    }
}

// MARK: - Stop
extension CameraView {
    func stop() {
        cameraFeedService.stopSession()
        clearhandLandmarkerServiceOnSessionInterruption()
    }
    
    private func clearhandLandmarkerServiceOnSessionInterruption() {
        handLandmarkerService = nil
    }
}

// MARK: - Resume Interrupted Session
extension CameraView {
    @objc private func didTapResume(_ sender: UIButton) {
        cameraFeedService.resumeInterruptedSession {[weak self] isSessionRunning in
            if isSessionRunning {
                self?.resumeButton.isHidden = true
                self?.cameraUnavailableLabel.isHidden = true
                self?.initializeHandLandmarkerServiceOnSessionResumption()
            }
        }
    }
}

extension CameraView: CameraFeedServiceDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation) {
        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        // Pass the pixel buffer to mediapipe
        backgroundQueue.async { [weak self] in
            self?.handLandmarkerService?.detectAsync(
                sampleBuffer: sampleBuffer,
                orientation: orientation,
                timeStamps: Int(currentTimeMs))
        }
    }
    
    // MARK: Session Handling Alerts
    func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
        // Updates the UI when session is interupted.
        if resumeManually {
            resumeButton.isHidden = false
        } else {
            cameraUnavailableLabel.isHidden = false
        }
        clearhandLandmarkerServiceOnSessionInterruption()
    }
    
    func sessionInterruptionEnded() {
        // Updates UI once session interruption has ended.
        cameraUnavailableLabel.isHidden = true
        resumeButton.isHidden = true
        initializeHandLandmarkerServiceOnSessionResumption()
    }
    
    func didEncounterSessionRuntimeError() {
        // Handles session run time error by updating the UI and providing a button if session can be
        // manually resumed.
        resumeButton.isHidden = false
        clearhandLandmarkerServiceOnSessionInterruption()
    }
    
}

extension CameraView: HandLandmarkerServiceLiveStreamDelegate {
    func handLandmarkerService(_ handLandmarkerService: HandLandmarkerService, 
                               didFinishDetection result: ResultBundle?,
                               error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            guard let handLandmarkerResult = result?.handLandmarkerResults.first as? HandLandmarkerResult else { return
            }
            let imageSize = strongSelf.cameraFeedService.videoResolution
            let handOverlays = OverlayView.handOverlays(
                fromMultipleHandLandmarks: handLandmarkerResult.landmarks,
                inferredOnImageOfSize: imageSize,
                ovelayViewSize: strongSelf.overlayView.bounds.size,
                imageContentMode: strongSelf.overlayView.imageContentMode,
                andOrientation: UIImage.Orientation.from(deviceOrientation: UIDevice.current.orientation)
            )
            strongSelf.overlayView.draw(
                handOverlays: handOverlays,
                inBoundsOfContentImageOfSize: imageSize,
                imageContentMode: strongSelf.cameraFeedService.videoGravity.contentMode
            )
        }
    }
}
