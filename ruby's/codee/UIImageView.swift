import UIKit

extension UIImageView {
    
    func applyBlur(radius: CGFloat = 3.0) {
            guard let image = self.image else { return }

            // Convert UIImage → CIImage
            let ciImage = CIImage(image: image)

            // Gaussian Blur filter
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(radius, forKey: kCIInputRadiusKey)

            // Context
            let context = CIContext(options: nil)

            // Render output
            if let output = filter?.outputImage,
               let cgImage = context.createCGImage(output, from: ciImage!.extent) {

                DispatchQueue.main.async {
                    self.image = UIImage(cgImage: cgImage)
                }
            }
        }
    
    func applyBlurEffect(style: UIBlurEffect.Style = .light, alpha: CGFloat = 1.0) {
        print("🔍 applyBlurEffect called - current bounds: \(self.bounds)")
        
        // Remove any existing blur effects
        self.subviews.filter({ $0 is UIVisualEffectView }).forEach { 
            print("🗑️ Removing existing blur view")
            $0.removeFromSuperview() 
        }
        
        // Ensure we have valid bounds
        guard !self.bounds.isEmpty else {
            print("⚠️ ImageView bounds are empty, cannot apply blur effect")
            return
        }
        
        // Try Core Image blur first
        if let image = self.image {
            let blurredImage = image.applyGaussianBlur(radius: 30.0)
            if let blurredImage = blurredImage {
                print("🔍 Applied Core Image blur effect with increased intensity")
                self.image = blurredImage
                return
            }
        }
        
        // Fallback to UIVisualEffectView
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = alpha
        
        print("🔍 Adding blur view with frame: \(blurView.frame), alpha: \(alpha)")
        self.addSubview(blurView)
        
        // Force layout update
        self.setNeedsLayout()
        self.layoutIfNeeded()
        blurView.setNeedsLayout()
        blurView.layoutIfNeeded()
        
        print("✅ Blur effect applied successfully")
    }
    
    
    func removeBlurEffect() {
        self.subviews.filter({ $0 is UIVisualEffectView }).forEach { $0.removeFromSuperview() }
    }
    
    func setGradientBorder(colors: [UIColor], borderWidth: CGFloat, cornerRadius: CGFloat? = nil) {
        // Remove any existing gradient border layers
        self.layer.sublayers?.removeAll { $0.name == "gradientBorder" }
        
        self.layoutIfNeeded()
        
        guard !self.bounds.isEmpty else { return }
        
        let radius = cornerRadius ?? (self.bounds.height / 2)
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "gradientBorder"
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = radius
        
        // Create outer path (full rounded rect)
        let outerPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: radius)
        
        // Create inner path (inset by borderWidth)
        let innerRect = self.bounds.insetBy(dx: borderWidth, dy: borderWidth)
        let innerRadius = max(0, radius - borderWidth)
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: innerRadius)
        
        // Create combined path for border (outer - inner)
        let borderPath = UIBezierPath()
        borderPath.append(outerPath)
        borderPath.append(innerPath.reversing())
        
        // Create mask layer
        let maskLayer = CAShapeLayer()
        maskLayer.path = borderPath.cgPath
        maskLayer.fillRule = .evenOdd
        
        gradientLayer.mask = maskLayer
        self.layer.addSublayer(gradientLayer)
    }
}

extension UIImage {
    func applyGaussianBlur(radius: Float) -> UIImage? {
        // Validate input
        guard radius > 0 else {
            print("⚠️ Invalid blur radius: \(radius)")
            return nil
        }
        
        // Ensure we have a valid image
        guard let ciImage = CIImage(image: self) else {
            print("⚠️ Failed to create CIImage from UIImage")
            return nil
        }
        
        // Create filter with error handling
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            print("⚠️ CIGaussianBlur filter not available")
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage else {
            print("⚠️ Filter output image is nil")
            return nil
        }
        
        // Crop to original extent to avoid edge artifacts from blur expansion
        let originalExtent = ciImage.extent
        
        // Ensure extent is valid
        guard !originalExtent.isInfinite && !originalExtent.isEmpty else {
            print("⚠️ Invalid image extent: \(originalExtent)")
            return nil
        }
        
        let croppedImage: CIImage
        do {
            croppedImage = outputImage.cropped(to: originalExtent)
        } catch {
            print("⚠️ Failed to crop output image: \(error)")
            return nil
        }
        
        // Create context with options for better device compatibility
        let contextOptions: [CIContextOption: Any] = [
            .useSoftwareRenderer: false, // Use hardware acceleration when available
            .workingColorSpace: CGColorSpaceCreateDeviceRGB()
        ]
        
        let context = CIContext(options: contextOptions)
        
        guard let cgImage = context.createCGImage(croppedImage, from: originalExtent) else {
            print("⚠️ Failed to create CGImage from blurred CIImage")
            // Fallback: try with default context
            let fallbackContext = CIContext()
            guard let fallbackCGImage = fallbackContext.createCGImage(croppedImage, from: originalExtent) else {
                print("⚠️ Fallback context also failed")
                return nil
            }
            return UIImage(cgImage: fallbackCGImage)
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Apply a slight blur effect to the image (optimized for card backgrounds)
    /// Uses a more visible blur radius that works consistently across all devices
    func applySlightBlur() -> UIImage? {
        // Use a higher radius (8.0) for more pronounced blur effect
        // This ensures strong blur visibility on all devices
        if let blurred = applyGaussianBlur(radius: 8.0) {
            return blurred
        }
        
        // Fallback: try with a medium radius if 8.0 fails
        print("⚠️ Primary blur failed, trying fallback radius 6.0")
        if let blurred = applyGaussianBlur(radius: 6.0) {
            return blurred
        }
        
        // Final fallback: try with lower radius
        print("⚠️ Fallback blur failed, trying minimum radius 4.0")
        return applyGaussianBlur(radius: 4.0)
    }
}
