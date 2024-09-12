//
//  UIImage+Orientation.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import UIKit

extension UIImage.Orientation {
    static func from(deviceOrientation: UIDeviceOrientation) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return .up
        case .landscapeLeft:
            return .left
        case .landscapeRight:
            return .right
        default:
            return .up
        }
    }
}

