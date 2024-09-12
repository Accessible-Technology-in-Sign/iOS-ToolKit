//
//  HandOverlay.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 10/09/24.
//

import UIKit
import MediaPipeTasksVision

/// Custom view to visualize the face landmarks result on top of the input image.
final class OverlayView: UIView {
    
    var handOverlays: [HandOverlay] = []
    
    private var contentImageSize: CGSize = CGSizeZero
    var imageContentMode: UIView.ContentMode = .scaleAspectFit
    private var orientation = UIDeviceOrientation.portrait
    
    private var edgeOffset: CGFloat = 0.0
    
    private var settings = SLRGTKSettings.defaultSettings.handlandmarkerSettings.getOverlaySettings()
    
    // MARK: Public Functions
    func draw(handOverlays: [HandOverlay],
              inBoundsOfContentImageOfSize imageSize: CGSize,
              edgeOffset: CGFloat = 0.0,
              imageContentMode: UIView.ContentMode) {
        self.clear()
        contentImageSize = imageSize
        self.edgeOffset = edgeOffset
        self.handOverlays = handOverlays
        self.imageContentMode = imageContentMode
        orientation = UIDevice.current.orientation
        self.setNeedsDisplay()
    }
    
    func redrawHandOverlays(forNewDeviceOrientation deviceOrientation:UIDeviceOrientation) {
        
        orientation = deviceOrientation
        
        switch orientation {
        case .portrait:
            fallthrough
        case .landscapeLeft:
            fallthrough
        case .landscapeRight:
            self.setNeedsDisplay()
        default:
            return
        }
    }
    
    func clear() {
        handOverlays = []
        contentImageSize = CGSize.zero
        imageContentMode = .scaleAspectFit
        orientation = UIDevice.current.orientation
        edgeOffset = 0.0
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        for handOverlay in handOverlays {
            drawLines(handOverlay.lines)
            drawDots(handOverlay.dots)
        }
    }
    
    // MARK: Private Functions
    private func rectAfterApplyingBoundsAdjustment(
        onOverlayBorderRect borderRect: CGRect) -> CGRect {
            
            var currentSize = self.bounds.size
            let minDimension = min(self.bounds.width, self.bounds.height)
            let maxDimension = max(self.bounds.width, self.bounds.height)
            
            switch orientation {
            case .portrait:
                currentSize = CGSizeMake(minDimension, maxDimension)
            case .landscapeLeft:
                fallthrough
            case .landscapeRight:
                currentSize = CGSizeMake(maxDimension, minDimension)
            default:
                break
            }
            
            let offsetsAndScaleFactor = OverlayView.offsetsAndScaleFactor(
                forImageOfSize: self.contentImageSize,
                tobeDrawnInViewOfSize: currentSize,
                withContentMode: imageContentMode)
            
            var newRect = borderRect
                .applying(
                    CGAffineTransform(scaleX: offsetsAndScaleFactor.scaleFactor, y: offsetsAndScaleFactor.scaleFactor)
                )
                .applying(
                    CGAffineTransform(translationX: offsetsAndScaleFactor.xOffset, y: offsetsAndScaleFactor.yOffset)
                )
            
            if newRect.origin.x < 0 &&
                newRect.origin.x + newRect.size.width > edgeOffset {
                newRect.size.width = newRect.maxX - edgeOffset
                newRect.origin.x = edgeOffset
            }
            
            if newRect.origin.y < 0 &&
                newRect.origin.y + newRect.size.height > edgeOffset {
                newRect.size.height += newRect.maxY - edgeOffset
                newRect.origin.y = edgeOffset
            }
            
            if newRect.maxY > currentSize.height {
                newRect.size.height = currentSize.height - newRect.origin.y  - edgeOffset
            }
            
            if newRect.maxX > currentSize.width {
                newRect.size.width = currentSize.width - newRect.origin.x - edgeOffset
            }
            
            return newRect
        }
    
    private func drawDots(_ dots: [CGPoint]) {
        for dot in dots {
            let dotRect = CGRect(
                x: CGFloat(dot.x) - settings.pointRadius / 2,
                y: CGFloat(dot.y) - settings.pointRadius / 2,
                width: settings.pointRadius,
                height: settings.pointRadius)
            let path = UIBezierPath(ovalIn: dotRect)
            settings.pointFillColor.setFill()
            settings.pointColor.setStroke()
            path.stroke()
            path.fill()
        }
    }
    
    private func drawLines(_ lines: [Line]) {
        let path = UIBezierPath()
        for line in lines {
            path.move(to: line.from)
            path.addLine(to: line.to)
        }
        path.lineWidth = settings.lineWidth
        settings.lineColor.setStroke()
        path.stroke()
    }
    
    // MARK: Helper Functions
    static func offsetsAndScaleFactor(
        forImageOfSize imageSize: CGSize,
        tobeDrawnInViewOfSize viewSize: CGSize,
        withContentMode contentMode: UIView.ContentMode)
    -> (xOffset: CGFloat, yOffset: CGFloat, scaleFactor: Double) {
        
        let widthScale = viewSize.width / imageSize.width;
        let heightScale = viewSize.height / imageSize.height;
        
        var scaleFactor = 0.0
        
        switch contentMode {
        case .scaleAspectFill:
            scaleFactor = max(widthScale, heightScale)
        case .scaleAspectFit:
            scaleFactor = min(widthScale, heightScale)
        default:
            scaleFactor = 1.0
        }
        
        let scaledSize = CGSize(
            width: imageSize.width * scaleFactor,
            height: imageSize.height * scaleFactor)
        let xOffset = (viewSize.width - scaledSize.width) / 2
        let yOffset = (viewSize.height - scaledSize.height) / 2
        
        return (xOffset, yOffset, scaleFactor)
    }
    
    // Helper to get object overlays from detections.
    static func handOverlays(
        fromMultipleHandLandmarks landmarks: [[NormalizedLandmark]],
        inferredOnImageOfSize originalImageSize: CGSize,
        ovelayViewSize: CGSize,
        imageContentMode: UIView.ContentMode,
        andOrientation orientation: UIImage.Orientation) -> [HandOverlay] {
            
            var handOverlays: [HandOverlay] = []
            
            guard !landmarks.isEmpty else {
                return []
            }
            
            let offsetsAndScaleFactor = OverlayView.offsetsAndScaleFactor(
                forImageOfSize: originalImageSize,
                tobeDrawnInViewOfSize: ovelayViewSize,
                withContentMode: imageContentMode)
            
            for handLandmarks in landmarks {
                var transformedHandLandmarks: [CGPoint]!
                
                switch orientation {
                case .left:
                    transformedHandLandmarks = handLandmarks.map({CGPoint(x: CGFloat($0.y), y: 1 - CGFloat($0.x))})
                case .right:
                    transformedHandLandmarks = handLandmarks.map({CGPoint(x: 1 - CGFloat($0.y), y: CGFloat($0.x))})
                default:
                    transformedHandLandmarks = handLandmarks.map({CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))})
                }
                
                let dots: [CGPoint] = transformedHandLandmarks.map({CGPoint(x: CGFloat($0.x) * originalImageSize.width * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.xOffset, y: CGFloat($0.y) * originalImageSize.height * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.yOffset)})
                let lines: [Line] = HandLandmarker.handConnections
                    .map({ connection in
                        let start = dots[Int(connection.start)]
                        let end = dots[Int(connection.end)]
                        return Line(from: start,
                                    to: end)
                    })
                
                handOverlays.append(HandOverlay(dots: dots, lines: lines))
            }
            
            return handOverlays
        }
}

