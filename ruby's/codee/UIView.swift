import UIKit
import Photos
import Foundation


extension UIView {
    
   
    func applyGradientBackgroundWithBorder(
        colors: [UIColor],
        borderColor: UIColor
    ) {
        // Remove old gradients if reapplying
        layer.sublayers?
            .filter { $0.name == "GradientBackgroundLayer" }
            .forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBackgroundLayer"
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }

        // Default: Top → Bottom
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)

        // ✅ Updated radius
        gradientLayer.cornerRadius = 16

        layer.insertSublayer(gradientLayer, at: 0)

        // Border
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = 4
        layer.cornerRadius = 16
        layer.masksToBounds = true
    }
    
    func applyRoundedBorder(
        cornerRadius: CGFloat = 10,
        borderWidth: CGFloat = 1,
        borderColor: UIColor? = UIColor(named: "BORDER_COLOR")
    ) {
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor?.cgColor
        self.clipsToBounds = true
    }
    
    func applyTextBlur(to labels: [UILabel], blurRadius: CGFloat = 6.0) {
        for label in labels {
            // Ensure label is laid out first
            label.layoutIfNeeded()
            
            // 1. Take a snapshot of the label
            UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                continue
            }
            label.layer.render(in: context)
            let snapshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let snapshotImage = snapshot else { continue }
            
            // 2. Apply Gaussian blur filter
            guard let ciImage = CIImage(image: snapshotImage),
                  let filter = CIFilter(name: "CIGaussianBlur") else { continue }
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(blurRadius, forKey: kCIInputRadiusKey)
            
            guard let output = filter.outputImage else { continue }
            let ciContext = CIContext()
            guard let cgImage = ciContext.createCGImage(output, from: ciImage.extent) else { continue }
            let blurredImage = UIImage(cgImage: cgImage)
            
            // 3. Create blur image view and position it correctly
            guard let superview = label.superview else { continue }
            let blurImageView = PassThroughImageView(image: blurredImage)
            // Use label's frame directly since both are in the same superview
            blurImageView.frame = label.frame
            blurImageView.layer.cornerRadius = label.layer.cornerRadius
            blurImageView.clipsToBounds = true
            
            // Add blur view on top (so it's visible) but allow touches to pass through
            superview.addSubview(blurImageView)
            
            // Make label text transparent but keep label visible for touch events
            // Setting alpha to 0 can cause iOS to skip hit testing
            label.textColor = .clear
        }
    }
    
    func applyGradientBorder(
            startColor: UIColor,
            endColor: UIColor,
            borderWidth: CGFloat = 3,
            cornerRadius: CGFloat = 8
        ) {
            // Remove existing gradient border if any
            layer.sublayers?
                .filter { $0.name == "GradientBorderLayer" }
                .forEach { $0.removeFromSuperlayer() }

            let gradientLayer = CAGradientLayer()
            gradientLayer.name = "GradientBorderLayer"
            gradientLayer.frame = bounds
            gradientLayer.colors = [
                startColor.cgColor,
                endColor.cgColor
            ]

            // Left → Right cross fade
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)

            let shapeLayer = CAShapeLayer()
            shapeLayer.lineWidth = borderWidth
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.black.cgColor
            
            // Inset the rect by half the border width so the stroke stays inside the bounds
            let insetRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
            let adjustedCornerRadius = max(cornerRadius - borderWidth / 2, 0)
            shapeLayer.path = UIBezierPath(
                roundedRect: insetRect,
                cornerRadius: adjustedCornerRadius
            ).cgPath

            gradientLayer.mask = shapeLayer
            layer.addSublayer(gradientLayer)
        }
}

// Custom UIImageView that allows touches to pass through
private class PassThroughImageView: UIImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Don't intercept touches - let them pass through to views below
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? nil : hitView
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
    
    func applyDropdownShadow(
        color: UIColor = UIColor.black,
        opacity: Float = 0.1,
        offset: CGSize = CGSize(width: 0, height: 4),
        radius: CGFloat = 8
    ) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.masksToBounds = false
    }
    
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func applySideAndBottomShadow(
        cornerRadius: CGFloat = 16,
        shadowColor: UIColor = UIColor.black,
        shadowOpacity: Float = 0.08,
        shadowRadius: CGFloat = 8,
        shadowOffset: CGSize = CGSize(width: 0, height: 4)
    ) {
        // Rounded corners
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = false
        
        // Shadow setup
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOffset = shadowOffset
        
        // Apply shadow only to left, right, and bottom by using shadowPath
        let path = UIBezierPath()
        let width = self.bounds.width
        let height = self.bounds.height
        
        path.move(to: CGPoint(x: 0, y: cornerRadius)) // top-left curve start
        path.addLine(to: CGPoint(x: 0, y: height)) // down left
        path.addLine(to: CGPoint(x: width, y: height)) // bottom right
        path.addLine(to: CGPoint(x: width, y: cornerRadius)) // up right
        
        self.layer.shadowPath = path.cgPath
    }
    
    func applyUniformColoredShadow(
        cornerRadius: CGFloat = 18,
        shadowColor: UIColor,
        shadowOpacity: Float = 0.45,
        shadowRadius: CGFloat = 6
    ) {
        // Rounded corners
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true  // Clip subviews to rounded corners
        self.layer.masksToBounds = false  // Allow shadow to extend beyond bounds
        
        // Shadow setup - uniform on all 4 sides
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOffset = CGSize(width: 0, height: 0)  // No offset for uniform shadow
        
        // Update shadow path to follow rounded corners
        self.updateShadowPath(cornerRadius: cornerRadius)
    }
    
    func updateShadowPath(cornerRadius: CGFloat) {
        self.layoutIfNeeded()
        let shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius)
        self.layer.shadowPath = shadowPath.cgPath
    }
    
    func applyCrossGradienttoView(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        self.layoutIfNeeded()

        self.layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.layer.cornerRadius

        // Mask and background handling
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(
            roundedRect: self.bounds,
            cornerRadius: self.layer.cornerRadius
        ).cgPath
        gradientLayer.mask = maskLayer

        self.layer.insertSublayer(gradientLayer, at: 0)
        self.backgroundColor = .clear
    }
    
    /// Adds gradient color from Bottom-Left → Top-Right
       func applyBottomLeftToTopRightGradient(
           colors: [UIColor]
       ) {
           layoutIfNeeded()

           // Remove existing gradient layers
           layer.sublayers?
               .filter { $0 is CAGradientLayer }
               .forEach { $0.removeFromSuperlayer() }

           let gradientLayer = CAGradientLayer()
           gradientLayer.colors = colors.map { $0.cgColor }

           // Bottom-Left → Top-Right direction
           gradientLayer.startPoint = CGPoint(x: 0, y: 1)
           gradientLayer.endPoint   = CGPoint(x: 1, y: 0)

           gradientLayer.frame = bounds
           gradientLayer.cornerRadius = layer.cornerRadius

           // Mask to respect corner radius
           let maskLayer = CAShapeLayer()
           maskLayer.path = UIBezierPath(
               roundedRect: bounds,
               cornerRadius: layer.cornerRadius
           ).cgPath

           gradientLayer.mask = maskLayer

           layer.insertSublayer(gradientLayer, at: 0)
           backgroundColor = .clear
       }
    
    func applyGradienttoView(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
        self.layoutIfNeeded() // Ensure the button's bounds are set
        
        // Remove any existing gradient layers
        self.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.layer.cornerRadius
        gradientLayer.masksToBounds = true
        
        // Ensure the gradient layer is inserted at the bottom
        self.layer.masksToBounds = true
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        // Create a shape layer for the button's shape
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        gradientLayer.mask = maskLayer
        
        // Set the background color of the button to clear
        self.backgroundColor = .clear
    }
    /// Generates a UIImage snapshot of this UIView (PNG-based).
    func generatePNGImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        return image
    }
    
    /// (Optional) Generates PNG data directly.
    func generatePNGData() -> Data? {
        return generatePNGImage()?.pngData()
    }
    /// Capture UIView as PNG data and save it to Photos
    func saveAsPNGToPhotos() {
        // 1️⃣ Convert view to image
        let image = asImage()
        
        // 2️⃣ Convert to PNG data
        guard let pngData = image.pngData() else {
            print("❌ Failed to generate PNG data.")
            return
        }
        
        // 3️⃣ Request Photos library permission
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                // 4️⃣ Save image to Photos
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: pngData, options: options)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("✅ PNG image saved successfully to Photos.")
                        } else if let error = error {
                            print("❌ Error saving image: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .denied, .restricted:
                DispatchQueue.main.async {
                    print("⚠️ Permission denied: enable Photos access in Settings.")
                }
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

}
