import UIKit

class ShimmerView: UIView {
    private let gradientLayer = CAGradientLayer()
    private var isAnimating = false
    private var didSetupGradient = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didSetupGradient {
            setupGradient()
            didSetupGradient = true
        } else {
            gradientLayer.frame = bounds
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if !didSetupGradient {
            setupGradient()
            didSetupGradient = true
        }
    }

    private func setupGradient() {
        backgroundColor = .clear // Remove background color
        
        gradientLayer.frame = bounds
        updateColors()
        
        // Diagonal shimmer
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        // Only one narrow highlight
        gradientLayer.locations = [0.45, 0.5, 0.55]
        
        layer.addSublayer(gradientLayer)
        startAnimating()
    }
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = false
        
        gradientLayer.add(animation, forKey: "shimmerAnimation")
    }
    
    func stopAnimating() {
        isAnimating = false
        gradientLayer.removeAnimation(forKey: "shimmerAnimation")
    }
    
    private func updateColors() {
        let bgColor = UIColor.clear.cgColor // Transparent background
        let shimmerColor = UIColor.white.withAlphaComponent(0.6).cgColor // Increased opacity for testing
        
        // Narrow highlight in the middle
        gradientLayer.colors = [
            bgColor,
            shimmerColor,
            bgColor
        ]
    }


    
    private func dynamicBackgroundColor() -> UIColor {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "2A2A2A") : UIColor(hex: "F0F0F0")
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundColor = .clear // Keep transparent
        updateColors()
    }
    
    deinit {
        gradientLayer.removeFromSuperlayer()
    }
}

// ✅ Helper to convert hex string to UIColor
extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hexString).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hexString.count {
        case 6: // RGB
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
    
    static var adaptiveLabelColor: UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
    }
}
