import UIKit

class UIHelper {
    static func applyBlackGradient(to view: UIView, isReversed: Bool = false, alpha: CGFloat = 0.6) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        
        if isReversed {
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(alpha).cgColor,
                UIColor.clear.cgColor
            ]
        } else {
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(alpha).cgColor
            ]
        }
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}
