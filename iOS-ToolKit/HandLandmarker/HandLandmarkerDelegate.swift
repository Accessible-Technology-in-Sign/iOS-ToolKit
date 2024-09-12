//
//  HandLandmarkerDelegate.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import Foundation
import MediaPipeTasksVision

// MARK: ImageClassifierDelegate
enum HandLandmarkerDelegate: CaseIterable {
    case GPU
    case CPU
    
    var name: String {
        switch self {
        case .GPU:
            return "GPU"
        case .CPU:
            return "CPU"
        }
    }
    
    var delegate: Delegate {
        switch self {
        case .GPU:
            return .GPU
        case .CPU:
            return .CPU
        }
    }
    
    init?(name: String) {
        switch name {
        case HandLandmarkerDelegate.CPU.name:
            self = HandLandmarkerDelegate.CPU
        case HandLandmarkerDelegate.GPU.name:
            self = HandLandmarkerDelegate.GPU
        default:
            return nil
        }
    }
}

