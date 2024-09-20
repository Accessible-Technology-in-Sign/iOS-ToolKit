//
//  CameraFeedService.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 09/09/24.
//

import UIKit
import AVFoundation

// MARK: CameraFeedServiceDelegate Declaration
protocol CameraFeedServiceDelegate: AnyObject {
    
    /**
     This method delivers the pixel buffer of the current frame seen by the device's camera.
     */
    func didOutput(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation)
    
    /**
     This method initimates that a session runtime error occured.
     */
    func didEncounterSessionRuntimeError()
    
    /**
     This method initimates that the session was interrupted.
     */
    func sessionWasInterrupted(canResumeManually resumeManually: Bool)
    
    /**
     This method initimates that the session interruption has ended.
     */
    func sessionInterruptionEnded()
    
}

/**
 This class manages all camera related functionality
 */
final class CameraFeedService: NSObject {
    /**
     This enum holds the state of the camera initialization.
     */
    enum CameraConfigurationStatus {
        case success
        case failed
        case permissionDenied
    }
    
    // MARK: Public Instance Variables
    var videoResolution: CGSize {
        get {
            guard let size = imageBufferSize else {
                return CGSize.zero
            }
            let minDimension = min(size.width, size.height)
            let maxDimension = max(size.width, size.height)
            switch UIDevice.current.orientation {
            case .portrait:
                return CGSize(width: minDimension, height: maxDimension)
            case .landscapeLeft:
                fallthrough
            case .landscapeRight:
                return CGSize(width: maxDimension, height: minDimension)
            default:
                return CGSize(width: minDimension, height: maxDimension)
            }
        }
    }
    
    let videoGravity = AVLayerVideoGravity.resizeAspectFill
    
    // MARK: Instance Variables
    private let session: AVCaptureSession = AVCaptureSession()
    private lazy var videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
    private let sessionQueue = DispatchQueue(label: "com.wavinDev.iOS-ToolKit.CameraFeedService.sessionQueue")
    private let cameraPosition: AVCaptureDevice.Position = .front
    
    private var cameraConfigurationStatus: CameraConfigurationStatus = .failed
    private lazy var videoDataOutput = AVCaptureVideoDataOutput()
    private var isSessionRunning = false
    private var imageBufferSize: CGSize?
    
    
    // MARK: CameraFeedServiceDelegate
    weak var delegate: CameraFeedServiceDelegate?
    
    // MARK: Initializer
    init(previewView: UIView) {
        super.init()
        
        // Initializes the session
        session.sessionPreset = .high
        setUpPreviewView(previewView)
        
        attemptToConfigureSession()
        NotificationCenter.default.addObserver(
            self, selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setUpPreviewView(_ view: UIView) {
        videoPreviewLayer.videoGravity = videoGravity
        videoPreviewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(videoPreviewLayer)
    }
    
    // MARK: notification methods
    @objc func orientationChanged(notification: Notification) {
        switch UIImage.Orientation.from(deviceOrientation: UIDevice.current.orientation) {
        case .up:
            videoPreviewLayer.connection?.videoOrientation = .portrait
        case .left:
            videoPreviewLayer.connection?.videoOrientation = .landscapeRight
        case .right:
            videoPreviewLayer.connection?.videoOrientation = .landscapeLeft
        default:
            break
        }
    }
    
    // MARK: Session Start and End methods
    
    /**
     This method starts an AVCaptureSession based on whether the camera configuration was successful.
     */
    
    func startLiveCameraSession(_ completion: @escaping(_ cameraConfiguration: CameraConfigurationStatus) -> Void) {
        sessionQueue.async {
            switch self.cameraConfigurationStatus {
            case .success:
                self.addObservers()
                self.startSession()
            default:
                break
            }
            completion(self.cameraConfigurationStatus)
        }
    }
    
    /**
     This method stops a running an AVCaptureSession.
     */
    func stopSession() {
        self.removeObservers()
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        
    }
    
    /**
     This method resumes an interrupted AVCaptureSession.
     */
    func resumeInterruptedSession(withCompletion completion: @escaping (Bool) -> ()) {
        sessionQueue.async {
            self.startSession()
            
            DispatchQueue.main.async {
                completion(self.isSessionRunning)
            }
        }
    }
    
    func updateVideoPreviewLayer(toFrame frame: CGRect) {
        videoPreviewLayer.frame = frame
    }
    
    /**
     This method starts the AVCaptureSession
     **/
    private func startSession() {
        self.session.startRunning()
        self.isSessionRunning = self.session.isRunning
    }
    
    // MARK: Session Configuration Methods.
    /**
     This method requests for camera permissions and handles the configuration of the session and stores the result of configuration.
     */
    private func attemptToConfigureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraConfigurationStatus = .success
        case .notDetermined:
            self.sessionQueue.suspend()
            self.requestCameraAccess(completion: { (granted) in
                self.sessionQueue.resume()
            })
        case .denied:
            self.cameraConfigurationStatus = .permissionDenied
        default:
            break
        }
        
        self.sessionQueue.async {
            self.configureSession()
        }
    }
    
    /**
     This method requests for camera permissions.
     */
    private func requestCameraAccess(completion: @escaping (Bool) -> ()) {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if !granted {
                self.cameraConfigurationStatus = .permissionDenied
            }
            else {
                self.cameraConfigurationStatus = .success
            }
            completion(granted)
        }
    }
    
    
    /**
     This method handles all the steps to configure an AVCaptureSession.
     */
    private func configureSession() {
        
        guard cameraConfigurationStatus == .success else {
            return
        }
        session.beginConfiguration()
        
        // Tries to add an AVCaptureDeviceInput.
        guard addVideoDeviceInput() == true else {
            self.session.commitConfiguration()
            self.cameraConfigurationStatus = .failed
            return
        }
        
        // Tries to add an AVCaptureVideoDataOutput.
        guard addVideoDataOutput() else {
            self.session.commitConfiguration()
            self.cameraConfigurationStatus = .failed
            return
        }
        
        session.commitConfiguration()
        self.cameraConfigurationStatus = .success
    }
    
    /**
     This method tries to an AVCaptureDeviceInput to the current AVCaptureSession.
     */
    private func addVideoDeviceInput() -> Bool {
        
        /**Tries to get the default front camera.
         */
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            return false
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                try setFrameRate(of: videoDeviceInput)
                return true
            }
            else {
                return false
            }
        }
        catch {
            fatalError("Cannot create video device input")
        }
    }
    
    private func setFrameRate(of videoDeviceInput: AVCaptureDeviceInput) throws {
        try videoDeviceInput.device.lockForConfiguration()
        
        let formats = videoDeviceInput.device.formats
        var bestFormat: AVCaptureDevice.Format?
        var maxResolution: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)

        for format in formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            
            // Check the supported frame rates for this format
            let frameRateRanges = format.videoSupportedFrameRateRanges
            let supports60fps = frameRateRanges.contains { $0.maxFrameRate >= 60 }
            
            // Find the highest resolution format that supports 60 fps
            if supports60fps && (dimensions.width * dimensions.height > maxResolution.width * maxResolution.height) {
                maxResolution = dimensions
                bestFormat = format
            }
        }
        
        if let bestFormat {
            videoDeviceInput.device.activeFormat = bestFormat
            videoDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
            videoDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
        }
        
        videoDeviceInput.device.unlockForConfiguration()
    }
    
    /**
     This method tries to an AVCaptureVideoDataOutput to the current AVCaptureSession.
     */
    private func addVideoDataOutput() -> Bool {
        
        let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [ String(kCVPixelBufferPixelFormatTypeKey) : kCMPixelFormat_32BGRA]
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
            if videoDataOutput.connection(with: .video)?.isVideoOrientationSupported == true
                && cameraPosition == .front {
                videoDataOutput.connection(with: .video)?.isVideoMirrored = true
            }
            return true
        }
        return false
    }
    
    // MARK: Notification Observer Handling
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeErrorOccured(_:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted(_:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded(_:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
    }
    
    // MARK: Notification Observers
    @objc func sessionWasInterrupted(_ notification: Notification) {
        
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            var canResumeManually = false
            if reason == .videoDeviceInUseByAnotherClient {
                canResumeManually = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                canResumeManually = false
            }
            
            self.delegate?.sessionWasInterrupted(canResumeManually: canResumeManually)
            
        }
    }
    
    @objc func sessionInterruptionEnded(_ notification: Notification) {
        self.delegate?.sessionInterruptionEnded()
    }
    
    @objc func sessionRuntimeErrorOccured(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }
        
        print("Capture session runtime error: \(error)")
        
        guard error.code == .mediaServicesWereReset else {
            self.delegate?.didEncounterSessionRuntimeError()
            return
        }
        
        sessionQueue.async {
            if self.isSessionRunning {
                self.startSession()
            } else {
                DispatchQueue.main.async {
                    self.delegate?.didEncounterSessionRuntimeError()
                }
            }
        }
    }
}

/**
 AVCaptureVideoDataOutputSampleBufferDelegate
 */
extension CameraFeedService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /** This method delegates the CVPixelBuffer of the frame seen by the camera currently.
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        if (imageBufferSize == nil) {
            imageBufferSize = CGSize(width: CVPixelBufferGetHeight(imageBuffer), height: CVPixelBufferGetWidth(imageBuffer))
        }
        delegate?.didOutput(sampleBuffer: sampleBuffer, orientation: UIImage.Orientation.from(deviceOrientation: UIDevice.current.orientation))
    }
}
