//
//  HandLandmarkerProcessor.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import Foundation
import MediaPipeTasksVision

enum HandLandmarkerProcessor: CaseIterable {
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
    
    var processor: Delegate {
        switch self {
        case .GPU:
            return .GPU
        case .CPU:
            return .CPU
        }
    }
    
    init?(name: String) {
        switch name {
        case HandLandmarkerProcessor.CPU.name:
            self = HandLandmarkerProcessor.CPU
        case HandLandmarkerProcessor.GPU.name:
            self = HandLandmarkerProcessor.GPU
        default:
            return nil
        }
    }
}

