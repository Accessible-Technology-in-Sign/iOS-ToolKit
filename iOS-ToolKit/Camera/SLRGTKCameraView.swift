//
//  CameraView.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 09/09/24.
//

import UIKit
import MediaPipeTasksVision

protocol SLRGTKCameraViewDelegate: AnyObject {
    func cameraViewDidBeginInferring()
    func cameraViewDidSetupEngine()
    func cameraViewDidInferSign(_ signInferenceResult: SignInferenceResult)
    func cameraViewDidThrowError(_ error: Error)
}

final class SLRGTKCameraView: UIView {
    
    weak var delegate: SLRGTKCameraViewDelegate?
    
    private lazy var buffer: Buffer<HandLandmarkerResult> = Buffer(capacity: settings.signInferenceSettings.numberOfFramesPerInference)
    
    private let handLandmarkerServiceQueue = DispatchQueue(
        label: "com.wavinDev.cameraView.handLandmarkerServiceQueue",
        attributes: .concurrent)
    
    private let backgroundQueue = DispatchQueue(label: "com.wavinDev.cameraView.backgroundQueue")
    
    private let overlayView = OverlayView()
    
    private var settings: SLRGTKSettings = .defaultSettings
    
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
    
    private lazy var cameraFeedService = CameraFeedService(previewView: self)
    
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
    
    private var signInferenceService: SignInferenceService?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cameraFeedService.updateVideoPreviewLayer(toFrame: bounds)
    }
    
    func setupEngine() {
        setupSignInferenceService()
        configureBuffer()
        delegate?.cameraViewDidSetupEngine()
    }
    
    private func setupUI() {
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
        
        // TODO: Resume and Camera Unavailable

    }
    
    private func configureBuffer() {
        buffer = Buffer(capacity: settings.signInferenceSettings.numberOfFramesPerInference)
    }
    
    private func setupSignInferenceService() {
        do {
            signInferenceService = try SignInferenceService(settings: settings.signInferenceSettings)
        } catch {
            delegate?.cameraViewDidThrowError(error)
        }
    }
}

// MARK: - Settings
extension SLRGTKCameraView {
    
    private func changeSettings(_ settings: SLRGTKSettings) {
        self.settings = settings
        reconfigureEngine()
    }
    
    private func reconfigureEngine() {
        clearAndInitializeHandLandmarkerService()
        configureBuffer()
        setupSignInferenceService()
    }
}

// MARK: - Start
extension SLRGTKCameraView {
    
    func start() {
        initializeHandLandmarkerServiceOnSessionResumption()
        cameraFeedService.startLiveCameraSession { [weak self] cameraConfiguration in
            DispatchQueue.main.async {
                switch cameraConfiguration {
                case .failed:
                    self?.delegate?.cameraViewDidThrowError(CameraError.configurationFailed)
                case .permissionDenied:
                    self?.delegate?.cameraViewDidThrowError(CameraError.permissionDenied)
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
        do {
            handLandmarkerService = try HandLandmarkerService(
                modelPath: settings.handlandmarkerSettings.modelPath.resourcePathString,
                numHands: settings.handlandmarkerSettings.numHands,
                minHandDetectionConfidence: settings.handlandmarkerSettings.minHandDetectionConfidence,
                minHandPresenceConfidence: settings.handlandmarkerSettings.minHandPresenceConfidence,
                minTrackingConfidence: settings.handlandmarkerSettings.minTrackingConfidence,
                delegate: settings.handlandmarkerSettings.handLandmarkerProcessor,
                resultsDelegate: self
            )
        } catch {
            delegate?.cameraViewDidThrowError(error)
        }
    }
}

// MARK: - Stop
extension SLRGTKCameraView {
    func stop() {
        cameraFeedService.stopSession()
        clearhandLandmarkerServiceOnSessionInterruption()
        buffer.clear(keepingCapacity: false)
    }
    
    private func clearhandLandmarkerServiceOnSessionInterruption() {
        handLandmarkerService = nil
    }
}

// MARK: - Detection
extension SLRGTKCameraView {
    
    func detect() {
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            
            var handLandmarks = strongSelf.buffer.items
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.cameraViewDidBeginInferring()
                if !strongSelf.settings.isContinuous {
                    strongSelf.stop()
                }
            }
            
            var inferenceData: [Float] = []
            
            let numberOfPointsPerLandmark = strongSelf.settings.signInferenceSettings.numberOfPointsPerLandmark
            let numberOfFramesPerInference = strongSelf.settings.signInferenceSettings.numberOfFramesPerInference
            
            guard !handLandmarks.isEmpty else {
                strongSelf.delegate?.cameraViewDidThrowError(DependencyError.noLandmarks)
                return
            }
            
            if handLandmarks.count < numberOfFramesPerInference {
                let midPoint = handLandmarks.count / 2
                
                for _ in 0 ..< (numberOfFramesPerInference - handLandmarks.count) {
                    handLandmarks.append(handLandmarks[midPoint])
                }
                
            }
            
            handLandmarks.forEach { landmark in
                guard let normalizedLandmarks = landmark.landmarks.first,
                      normalizedLandmarks.count == numberOfPointsPerLandmark else {
                    strongSelf.delegate?.cameraViewDidThrowError(DependencyError.landmarkStructure)
                    return // TODO: Keep this condition in sync with Android
                }
                
                for i in 0 ..< numberOfPointsPerLandmark {
                    inferenceData.append(normalizedLandmarks[i].x)
                    inferenceData.append(normalizedLandmarks[i].y)
                }
            }
            
            if let inferenceResults = strongSelf.signInferenceService?.runModel(using: inferenceData) {
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.cameraViewDidInferSign(inferenceResults)
                }
            }
        }
    }
}

// MARK: - Resume Interrupted Session
extension SLRGTKCameraView {
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

extension SLRGTKCameraView: CameraFeedServiceDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation) {
        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        // Pass the pixel buffer to mediapipe
        backgroundQueue.async { [weak self] in
            self?.handLandmarkerService?.detectAsync(
                sampleBuffer: sampleBuffer,
                orientation: orientation,
                timeStamps: Int(currentTimeMs)
            )
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

extension SLRGTKCameraView: HandLandmarkerServiceLiveStreamDelegate {
    func handLandmarkerService(_ handLandmarkerService: HandLandmarkerService, 
                               didFinishDetection result: HandLandmarkerResultBundle?,
                               error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            guard let handLandmarkerResult = result?.handLandmarkerResults.first as? HandLandmarkerResult else { return
            }
            
            if !handLandmarkerResult.landmarks.isEmpty {
                strongSelf.buffer.addItem(handLandmarkerResult)
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
