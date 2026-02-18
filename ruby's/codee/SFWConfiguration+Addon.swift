import Foundation
import UIKit

public extension SFWConfiguration {
    static var variousWheelJackpotConfiguration: SFWConfiguration {
        
        let pin = SFWConfiguration.PinImageViewPreferences(size: CGSize(width: 13, height: 40), position: .top, verticalOffset: -25)
        
        let spin = SFWConfiguration.SpinButtonPreferences(size: CGSize(width: 55, height: 55))
        
        let sliceColorType = SFWConfiguration.ColorType.customPatternColors(colors: nil, defaultColor: .clear)
        let slicePreferences = SFWConfiguration.SlicePreferences(backgroundColorType:  sliceColorType , strokeWidth: 0, strokeColor: UIColor.redYellowGradient())
        
        let circlePreferences = SFWConfiguration.CirclePreferences(strokeWidth: 0, strokeColor: UIColor(named: "yellowBG")!)
        
        let wheelPreferences = SFWConfiguration.WheelPreferences(circlePreferences: circlePreferences, slicePreferences: slicePreferences, startPosition: .top)
        
        let configuration = SFWConfiguration(wheelPreferences: wheelPreferences, pinPreferences: pin, spinButtonPreferences: spin)
        
        return configuration
    }
}

extension UIColor {
    
    static func redYellowGradient() -> UIColor {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.yellowBG.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        UIGraphicsBeginImageContextWithOptions(gradientLayer.bounds.size, false, 0)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIColor(patternImage: gradientImage!)
    }
}

func gradientColor(startHex: String, endHex: String, size: CGSize, angleDegrees: CGFloat) -> UIColor {
    let startColor = UIColor(hex: startHex)
    let endColor = UIColor(hex: endHex)
    
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = CGRect(origin: .zero, size: size)
    gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    guard let context = UIGraphicsGetCurrentContext() else { return startColor }
    
    // Rotate context for angular effect
    context.translateBy(x: size.width / 2, y: size.height / 2)
    context.rotate(by: angleDegrees * CGFloat.pi / 180)
    context.translateBy(x: -size.width / 2, y: -size.height / 2)
    
    gradientLayer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return UIColor(patternImage: image ?? UIImage())
}
