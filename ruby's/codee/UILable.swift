import UIKit
import ObjectiveC

private var gradientLayerKey: UInt8 = 0

extension UILabel {
    var calculatedNumberOfLines: Int {
        guard let text = self.text, !text.isEmpty else { return 0 }
        guard let font = self.font else { return 0 }
        
        // Force layout to ensure proper sizing
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        // Get the actual width from the label's bounds or frame
        let labelWidth = self.bounds.width > 0 ? self.bounds.width : self.frame.width
        
        // If width is still 0 or very small, return 1 (single line)
        guard labelWidth > 10 else { return 1 }
        
        // Create a temporary label with the same properties to calculate accurately
        let tempLabel = UILabel()
        tempLabel.text = text
        tempLabel.font = font
        tempLabel.numberOfLines = 0
        tempLabel.lineBreakMode = self.lineBreakMode
        tempLabel.textAlignment = self.textAlignment
        
        // Calculate the size that fits within the label's width
        let maxSize = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)
        let textSize = tempLabel.sizeThatFits(maxSize)
        
        // Calculate number of lines based on height
        let lineHeight = font.lineHeight
        let numberOfLines = Int(ceil(textSize.height / lineHeight))
        
        // Ensure we return at least 1 line
        return max(1, numberOfLines)
    }
    
    var isSingleLine: Bool {
        return calculatedNumberOfLines == 1
    }
    
    // More reliable single line check
    var isActuallySingleLine: Bool {
        guard let text = self.text, !text.isEmpty else { return true }
        guard let font = self.font else { return true }
        
        // Force layout
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let labelWidth = self.bounds.width > 0 ? self.bounds.width : self.frame.width
        guard labelWidth > 10 else { return true }
        
        // Calculate the width needed for the text in a single line
        let singleLineWidth = (text as NSString).size(withAttributes: [.font: font]).width
        
        // If the text width is less than or equal to the label width, it's single line
        return singleLineWidth <= labelWidth
    }
    
    // Alternative method using boundingRect
    var calculatedNumberOfLinesAlternative: Int {
        guard let text = self.text, !text.isEmpty else { return 0 }
        guard let font = self.font else { return 0 }
        
        // Force layout
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let labelWidth = self.bounds.width > 0 ? self.bounds.width : self.frame.width
        guard labelWidth > 10 else { return 1 }
        
        // Use boundingRect for more accurate calculation
        let maxSize = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let textHeight = (text as NSString).boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).height
        
        let lineHeight = font.lineHeight
        let numberOfLines = Int(ceil(textHeight / lineHeight))
        
        return max(1, numberOfLines)
    }
    
    func applyGradientBackgroundBehindText(colors: [UIColor],
                                           startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
                                           endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
        self.layoutIfNeeded()
        
        self.layer.sublayers?.filter { $0.name == "labelGradientLayer" }.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "labelGradientLayer"
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.layer.cornerRadius
        
        gradientLayer.zPosition = -1
        
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        self.textColor = .white
        self.backgroundColor = .clear
    }
    
    func visibleLineCount() -> Int {
        guard let text = self.text, !text.isEmpty else { return 0 }
        
        // Force layout update to get correct frame
        self.layoutIfNeeded()
        
        let maxSize = CGSize(
            width: self.bounds.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: self.font as Any
        ]
        
        let textRect = text.boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        
        let lineHeight = self.font.lineHeight
        return Int(ceil(textRect.height / lineHeight))
    }
}
