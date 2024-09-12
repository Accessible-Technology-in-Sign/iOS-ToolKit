//
//  HandLandmarkerService.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 09/09/24.
//

import UIKit
import MediaPipeTasksVision
import AVFoundation

/**
 This protocol must be adopted by any class that wants to get the detection results of the hand landmarker in live stream mode.
 */
protocol HandLandmarkerServiceLiveStreamDelegate: AnyObject {
    func handLandmarkerService(_ handLandmarkerService: HandLandmarkerService, didFinishDetection result: HandLandmarkerResultBundle?, error: Error?)
}

/**
 This protocol must be adopted by any class that wants to take appropriate actions during  different stages of hand landmark on videos.
 */
protocol HandLandmarkerServiceVideoDelegate: AnyObject {
    func handLandmarkerService(_ handLandmarkerService: HandLandmarkerService, didFinishDetectionOnVideoFrame index: Int)
    func handLandmarkerService(_ handLandmarkerService: HandLandmarkerService, willBeginDetection totalframeCount: Int)
}


// Initializes and calls the MediaPipe APIs for detection.
final class HandLandmarkerService: NSObject {
    
    private weak var liveStreamDelegate: HandLandmarkerServiceLiveStreamDelegate?
    
    private var handLandmarker: HandLandmarker?
    private(set) var runningMode = RunningMode.image
    private var numHands: Int
    private var minHandDetectionConfidence: Float
    private var minHandPresenceConfidence: Float
    private var minTrackingConfidence: Float
    var modelPath: String
    private var delegate: HandLandmarkerProcessor
    
    // MARK: - Custom Initializer
    init(modelPath: String?,
         runningMode: RunningMode = .liveStream,
         numHands: Int,
         minHandDetectionConfidence: Float,
         minHandPresenceConfidence: Float,
         minTrackingConfidence: Float,
         delegate: HandLandmarkerProcessor,
         resultsDelegate: HandLandmarkerServiceLiveStreamDelegate) throws {
        guard let modelPath else {
            throw PathError.handLandmarker
        }
        self.modelPath = modelPath
        self.runningMode = runningMode
        self.numHands = numHands
        self.minHandDetectionConfidence = minHandDetectionConfidence
        self.minHandPresenceConfidence = minHandPresenceConfidence
        self.minTrackingConfidence = minTrackingConfidence
        self.delegate = delegate
        self.liveStreamDelegate = resultsDelegate
        super.init()
        
        createHandLandmarker()
    }
    
    private func createHandLandmarker() {
        let handLandmarkerOptions = HandLandmarkerOptions()
        handLandmarkerOptions.runningMode = runningMode
        handLandmarkerOptions.numHands = numHands
        handLandmarkerOptions.minHandDetectionConfidence = minHandDetectionConfidence
        handLandmarkerOptions.minHandPresenceConfidence = minHandPresenceConfidence
        handLandmarkerOptions.minTrackingConfidence = minTrackingConfidence
        handLandmarkerOptions.baseOptions.modelAssetPath = modelPath
        handLandmarkerOptions.baseOptions.delegate = delegate.processor
        if runningMode == .liveStream {
            handLandmarkerOptions.handLandmarkerLiveStreamDelegate = self
        }
        do {
            handLandmarker = try HandLandmarker(options: handLandmarkerOptions)
        }
        catch {
            print(error)
        }
    }
    
    // MARK: - Static Initializers
    func detectAsync(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation, timeStamps: Int) {
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            return
        }
        do {
            try handLandmarker?.detectAsync(image: image, timestampInMilliseconds: timeStamps)
        } catch {
            print(error)
        }
    }
}

// MARK: - HandLandmarkerLiveStreamDelegate Methods
extension HandLandmarkerService: HandLandmarkerLiveStreamDelegate {
    func handLandmarker(_ handLandmarker: HandLandmarker,
                        didFinishDetection result: HandLandmarkerResult?,
                        timestampInMilliseconds: Int,
                        error: Error?) {
        
        let resultBundle = HandLandmarkerResultBundle(
            inferenceTime: Date().timeIntervalSince1970 * 1000 - Double(timestampInMilliseconds),
            handLandmarkerResults: [result]
        )
        liveStreamDelegate?.handLandmarkerService(self, didFinishDetection: resultBundle, error: error)
    }
}
