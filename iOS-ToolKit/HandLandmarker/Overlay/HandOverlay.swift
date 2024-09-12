//
//  HandOverlay.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import Foundation

/**
 This structure holds the display parameters for the overlay to be drawon on a hand landmarker object.
 */
struct HandOverlay {
  let dots: [CGPoint]
  let lines: [Line]
}
