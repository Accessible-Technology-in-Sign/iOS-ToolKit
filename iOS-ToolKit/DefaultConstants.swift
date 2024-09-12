//
//  DefaultConstants.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 10/09/24.
//

import UIKit
import MediaPipeTasksVision

// MARK: Define default constants
struct DefaultConstants {

  static let lineWidth: CGFloat = 2
  static let pointRadius: CGFloat = 5
  static let pointColor = UIColor.yellow
  static let pointFillColor = UIColor.red
  static let lineColor = UIColor(red: 0, green: 127/255.0, blue: 139/255.0, alpha: 1)

  static var numHands: Int = 1
  static var minHandDetectionConfidence: Float = 0.5
  static var minHandPresenceConfidence: Float = 0.5
  static var minTrackingConfidence: Float = 0.5
  static let modelPath: String? = Bundle.main.path(forResource: "hand_landmarker", ofType: "task")
  static let delegate: HandLandmarkerDelegate = .CPU
}

