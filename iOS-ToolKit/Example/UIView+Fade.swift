//
//  UIView+Extensions.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 12/09/24.
//

import UIKit

extension UIView {
    func fadeIn(in duration: TimeInterval = 0.2, onCompletion: (() -> Void)? = nil) {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
            
        },
        completion: { (value: Bool) in
            if let complete = onCompletion { complete() }
        })
    }

    func fadeOut(in duration: TimeInterval = 0.2, onCompletion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
            
        },
        completion: { [weak self] (value: Bool) in
            self?.isHidden = true
            if let complete = onCompletion { complete() }
        })
    }
}
