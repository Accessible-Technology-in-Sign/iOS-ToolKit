//
//  SLRGTKSettings.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import UIKit
import MediaPipeTasksVision

struct SLRGTKSettings {
    
    let isContinuous: Bool
    
    let handlandmarkerSettings: HandLandmarkerSettings
    let signInferenceSettings: SignInferenceSettings
    
    static var defaultSettings: SLRGTKSettings = SLRGTKSettings(
        isContinuous: false,
        handlandmarkerSettings: HandLandmarkerSettings(),
        signInferenceSettings: SignInferenceSettings()
    )
}

struct HandLandmarkerSettings {
    let lineWidth: CGFloat
    let pointRadius: CGFloat
    let pointColor: UIColor
    let pointFillColor: UIColor
    let lineColor: UIColor

    let numHands: Int
    let minHandDetectionConfidence: Float
    let minHandPresenceConfidence: Float
    let minTrackingConfidence: Float
    let modelPath: AssetPath
    let handLandmarkerProcessor: HandLandmarkerProcessor
    
    init(lineWidth: CGFloat = 2,
         pointRadius: CGFloat = 5,
         pointColor: UIColor = .yellow,
         pointFillColor: UIColor = .red,
         lineColor: UIColor = UIColor(red: 0, green: 127/255.0, blue: 139/255.0, alpha: 1),
         numHands: Int = 1,
         minHandDetectionConfidence: Float = 0.5,
         minHandPresenceConfidence: Float = 0.5,
         minTrackingConfidence: Float = 0.5,
         modelPath: AssetPath = AssetPath(name: "hand_landmarker", fileExtension: "task"),
         handLandmarkerProcessor: HandLandmarkerProcessor = .GPU
     ) {
        self.lineWidth = lineWidth
        self.pointRadius = pointRadius
        self.pointColor = pointColor
        self.pointFillColor = pointFillColor
        self.lineColor = lineColor
        self.numHands = numHands
        self.minHandDetectionConfidence = minHandDetectionConfidence
        self.minHandPresenceConfidence = minHandPresenceConfidence
        self.minTrackingConfidence = minTrackingConfidence
        self.modelPath = modelPath
        self.handLandmarkerProcessor = handLandmarkerProcessor
    }
    
    struct OverlaySettings {
        let lineWidth: CGFloat
        let pointRadius: CGFloat
        let pointColor: UIColor
        let pointFillColor: UIColor
        let lineColor: UIColor
    }
    
    func getOverlaySettings() -> OverlaySettings {
        return OverlaySettings(lineWidth: lineWidth, pointRadius: pointRadius, pointColor: pointColor, pointFillColor: pointFillColor, lineColor: lineColor)
    }
}

struct SignInferenceSettings {
    
    let numberOfFramesPerInference: Int
    let numberOfPointsPerLandmark: Int
    
    let threadCount: Int
    let modelPath: AssetPath
    let labelsPath: AssetPath
    
    init(numberOfFramesPerInference: Int = 60,
         numberOfPointsPerLandmark: Int = 21,
         threadCount: Int = 1,
         modelPath: AssetPath = AssetPath(name: "model_2", fileExtension: "tflite"),
         labelsPath: AssetPath = AssetPath(name: "signsList", fileExtension: "txt")
    ) {
        self.numberOfFramesPerInference = numberOfFramesPerInference
        self.numberOfPointsPerLandmark = numberOfPointsPerLandmark
        self.threadCount = threadCount
        self.modelPath = modelPath
        self.labelsPath = labelsPath
    }
}
    
