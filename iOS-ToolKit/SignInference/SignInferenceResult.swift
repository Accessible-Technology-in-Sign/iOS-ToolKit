//
//  InferenceResult.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import Foundation

/**
 Stores one formatted inference.
 */
struct SignInference {
    let confidence: Float
    let label: String
}

struct SignInferenceResult {
    let inferenceTime: Double
    let inferences: [SignInference]
}

