//
//  Error.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import Foundation

protocol SLRGTKError: LocalizedError {
    var title: String { get }
    var errorMessage: String { get }
}

enum PathError: SLRGTKError {
    case handLandmarker
    case signInference
    case labels
    
    var title: String {
        return String(localized: "Path Error")
    }
    
    var errorMessage: String {
        switch self {
        case .handLandmarker:
            return String(localized: "Path for landmarker model not found")
        case .signInference:
            return String(localized: "Path for gesture inference model not found")
        case .labels:
            return String(localized: "Path for gesture inference labels not found")
        }
    }
    
    var errorDescription: String? {
        return errorMessage
    }
}

enum CorruptedFileError: SLRGTKError {
    case labels(path: String)
    
    var title: String {
        return "Error Reading File"
    }
    
    var errorMessage: String {
        switch self {
        case .labels(let path):
            return "Labels file at path: \(path) could not be read"
        }
    }
    
    var errorDescription: String? {
        return errorMessage
    }
}

enum PassAlongError: SLRGTKError {
    case tensorFlow(message: String)
    
    var title: String {
        switch self {
        case .tensorFlow:
            return "Error Working with Tensor Flow"
        }
    }
    
    var errorMessage: String {
        switch self {
        case .tensorFlow(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        return errorMessage
    }
}

enum CameraError: SLRGTKError {
    case configurationFailed
    case permissionDenied
    
    var title: String {
        return String(localized: "Error Configuring Camera")
    }
    
    var errorMessage: String {
        switch self {
        case .configurationFailed:
            return String(localized: "There was an error while configuring camera")
        case .permissionDenied:
            return String(localized: "Camera permissions have been denied for this app. You can change this by going to Settings")
        }
    }
    
    var errorDescription: String? {
        return errorMessage
    }
}

enum DependencyError: SLRGTKError {
    case noLandmarks
    case landmarkStructure
    
    var title: String {
        switch self {
        case .noLandmarks, .landmarkStructure:
            return String(localized: "Hand Landmarking failed")
        
        }
    }
    
    var errorMessage: String {
        switch self {
        case .noLandmarks:
            return String(localized: "Hand Landmarking output is empty. Please contact our developers")
        case .landmarkStructure:
            return String(localized: "Hand Landmarking output is corrupted. Please contact our developers")
        }
    }
    
    var errorDescription: String? {
        return errorMessage
    }
}
