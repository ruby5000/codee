import UIKit
import Foundation

extension UIButton {
    func setGradientBorder(colors: [UIColor], borderWidth: CGFloat) {
        layer.sublayers?.removeAll { $0 is CAGradientLayer }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = borderWidth
        shapeLayer.strokeColor = UIColor.clear.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        let path = UIBezierPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        shapeLayer.path = path.cgPath
        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }
    
    func applyGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
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
    func startPerfectAnimation() {
        // 🌟 Start Rotation
        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation")
        rotationAnimation.values = [-1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0].map { $0 * (.pi / 180) }
        rotationAnimation.keyTimes = Array(0...8).map { NSNumber(value: Double($0) / 8.0) }
        rotationAnimation.duration = 1.2
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.isAdditive = true
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.layer.add(rotationAnimation, forKey: "smoothRotation")
        
        // 🌟 Start Pulse & Shake Loop
        animatePerfectSequence()
    }
    
    private func animatePerfectSequence() {
        // Scale Up
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
            self.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        }) { _ in
            // Scale Down Bounce
            UIView.animateKeyframes(withDuration: 0.4,
                                    delay: 0,
                                    options: [.calculationModeCubic],
                                    animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                    self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.4) {
                    self.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
                    self.transform = .identity
                }
            }, completion: { _ in
                self.performShake()
            })
        }
    }
    
    private func performShake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation")
        animation.duration = 1.2
        animation.values = (0..<15).map {
            let angle = Double($0) / 14.0 * 2 * Double.pi
            let x = CGFloat(sin(angle) * 1.8)
            let y = CGFloat(cos(angle) * 5.0)
            return NSValue(cgSize: CGSize(width: x, height: y))
        }
        animation.keyTimes = (0..<15).map { NSNumber(value: Double($0)/14.0) }
        animation.isAdditive = true
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1.0)
        self.layer.add(animation, forKey: "shake")
        
        // Loop the full sequence with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.animatePerfectSequence()
        }
    }
    
    func stopPerfectAnimation() {
        self.layer.removeAnimation(forKey: "shake")
        self.layer.removeAnimation(forKey: "smoothRotation")
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
        }
    }
}
