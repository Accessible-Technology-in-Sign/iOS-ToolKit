//
//  ResultBundke.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import Foundation
import MediaPipeTasksVision

/// A result from the `HandLandmarkerService`.
struct HandLandmarkerResultBundle {
    let inferenceTime: Double
    let handLandmarkerResults: [HandLandmarkerResult?]
    var size: CGSize = .zero
}
