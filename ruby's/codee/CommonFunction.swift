import UIKit
import Alamofire
import Foundation
import UIKit
import Photos

final class GradientHelper {

    static func applyInboxBottomGradient(
        on view: UIView,
        traitCollection: UITraitCollection,
        existingLayer: inout CAGradientLayer?
    ) {
        // Remove old gradient
        existingLayer?.removeFromSuperlayer()

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds

        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseColor: UIColor = isDark ? .black : .white

        gradient.colors = [
            baseColor.withAlphaComponent(0.0).cgColor, // 0%
            baseColor.withAlphaComponent(0.85).cgColor, // 85%
            baseColor.withAlphaComponent(1.0).cgColor  // 100%
        ]

        // 👇 Exact stop positions
        gradient.locations = [
            0.0,   // 0%
            0.85,  // 85%
            1.0    // 100%
        ]

        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1.0)

        view.layer.insertSublayer(gradient, at: 0)
        existingLayer = gradient
    }
}



func createAttributedText(
    fullText: String,
    highlights: [(text: String, font: UIFont, color: UIColor)],
    defaultFont: UIFont,
    defaultColor: UIColor
) -> NSAttributedString {
    
    let attributedString = NSMutableAttributedString(string: fullText)
    
    attributedString.addAttributes([
        .font: defaultFont,
        .foregroundColor: defaultColor
    ], range: NSRange(location: 0, length: fullText.utf16.count))
    
    for highlight in highlights {
        let ranges = fullText.ranges(of: highlight.text)
        for range in ranges {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttributes([
                .font: highlight.font,
                .foregroundColor: highlight.color
            ], range: nsRange)
        }
    }
    
    return attributedString
}


func isConnectedToInternet() -> Bool {
    let networkManager = NetworkReachabilityManager()
    return networkManager?.isReachable ?? false
}

func applyDirectionalShadow(to view: UIView) {
    view.layer.masksToBounds = false
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.09   // lighter
    view.layer.shadowRadius = 5       // smaller blur
    view.layer.cornerRadius = 22
    view.layer.shadowOffset = CGSize(width: 0, height: 2) // subtle downward shadow
    
    // Less spread
    let shadowInsetX: CGFloat = -1
    let shadowInsetY: CGFloat = -1
    let shadowRect = view.bounds.insetBy(dx: shadowInsetX, dy: shadowInsetY)
    view.layer.shadowPath = UIBezierPath(
        roundedRect: shadowRect,
        cornerRadius: view.layer.cornerRadius
    ).cgPath
}


func applyShadow(to view: UIView) {
    view.layer.masksToBounds = false
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.1
    view.layer.shadowRadius = 8
    view.layer.shadowOffset = CGSize(width: 0, height: 0) // neutral offset
    
    // Expand shadow in all directions (top, left, right, bottom)
    let shadowInsetX: CGFloat = -4   // Left & right shadow
    let shadowInsetY: CGFloat = -4   // Top & bottom shadow
    let shadowRect = view.bounds.insetBy(dx: shadowInsetX, dy: shadowInsetY)
    
    view.layer.shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: view.layer.cornerRadius).cgPath
}

func convertToBase64(_ input: String) -> String? {
    guard let data = input.data(using: .utf8) else { return nil }
    return data.base64EncodedString()
}

func decodeBase64String(_ base64String: String) -> String? {
    guard let data = Data(base64Encoded: base64String) else {
        print("❌ Failed to decode Base64 string to Data.")
        return nil
    }
    return String(data: data, encoding: .utf8)
}

func applyBottomCornerRadius(to view: UIView, radius: Int) {
    view.clipsToBounds = true
    view.layer.cornerRadius = CGFloat(radius)
    view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
}

func clearPasteboard() {
    if let pasteboard = UIPasteboard.general.string, !pasteboard.isEmpty {
        UIPasteboard.general.string = nil
        print("Pasteboard cleared.")
    } else {
        print("Pasteboard already empty.")
    }
}

func isSmallDevice() -> Bool {
    return UIScreen.main.bounds.height == 667
}

func isIpad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}


func numberOfVisibleLines(for label: UILabel) -> Int {
    // Force layout
    label.setNeedsLayout()
    label.layoutIfNeeded()

    // 🔑 CRITICAL FIX FOR SMALL DEVICES
    if label.preferredMaxLayoutWidth == 0 {
        label.preferredMaxLayoutWidth = label.frame.width
    }

    guard let text = label.text, let font = label.font else { return 0 }

    let maxSize = CGSize(
        width: label.preferredMaxLayoutWidth,
        height: .greatestFiniteMagnitude
    )

    let attributes: [NSAttributedString.Key: Any] = [.font: font]

    let textRect = (text as NSString).boundingRect(
        with: maxSize,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes,
        context: nil
    )

    let lineHeight = font.lineHeight
    let lines = Int(ceil(textRect.height / lineHeight))

    // 🔐 Clamp to UILabel's visible height (only if bounds height is reasonable)
    // Check if bounds height is reasonable to avoid Int overflow
    let boundsHeight = label.bounds.height
    let maxReasonableHeight: CGFloat = 10000 // Reasonable max height for a label
    
    if boundsHeight > 0 && boundsHeight < maxReasonableHeight && lineHeight > 0 {
        let maxVisibleLines = Int(floor(boundsHeight / lineHeight))
        return min(lines, maxVisibleLines)
    } else {
        // If bounds height is too large or invalid, return calculated lines without clamping
        return lines
    }
}

// Overload for calculating lines without a label (uses same logic as numberOfVisibleLines)
func numberOfVisibleLines(text: String, font: UIFont, width: CGFloat) -> Int {
    guard !text.isEmpty else { return 0 }
    
    // 🔑 CRITICAL FIX FOR SMALL DEVICES - use provided width as preferredMaxLayoutWidth
    let preferredMaxLayoutWidth = width > 0 ? width : 0
    
    let maxSize = CGSize(
        width: preferredMaxLayoutWidth,
        height: .greatestFiniteMagnitude
    )

    let attributes: [NSAttributedString.Key: Any] = [.font: font]

    let textRect = (text as NSString).boundingRect(
        with: maxSize,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes,
        context: nil
    )

    let lineHeight = font.lineHeight
    let lines = Int(ceil(textRect.height / lineHeight))

    // For this overload, we don't clamp to visible height since we're calculating for sizing
    return lines
}




func calculateDiscountLabel(originalPrice: Any, discountedPrice: Any) -> String {
    // Helper to convert to Double
    func toDouble(_ value: Any) -> Double? {
        switch value {
        case let str as String:
            return Double(str)
        case let num as NSNumber:
            return num.doubleValue
        case let dec as NSDecimalNumber:
            return dec.doubleValue
        default:
            return nil
        }
    }
    
    guard let original = toDouble(originalPrice),
          let discounted = toDouble(discountedPrice),
          original > 0 else {
        return ""
    }
    
    let discount = ((original - discounted) / original) * 100
    let roundedDiscount = Int(round(discount))
    let localizedTemplate = NSLocalizedString("discount_save_label", comment: "")
    return String(format: localizedTemplate, roundedDiscount)
}


func clearAllAppStorage() {
    let fileManager = FileManager.default
    
    // 1️⃣ Caches Directory
    if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
        deleteAllFiles(in: cacheURL)
    }
    
    // 2️⃣ Temporary Directory
    let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    deleteAllFiles(in: tmpDir)
    
    // 3️⃣ Documents Directory (⚠️ Optional)
    // Only clear if you intentionally store temporary media here (not user data)
    if let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        deleteAllFiles(in: docURL)
    }
    
    print("🧹 All possible app directories cleared (cache, tmp, docs).")
}

private func deleteAllFiles(in directory: URL) {
    let fileManager = FileManager.default
    do {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }
        print("✅ Cleared: \(directory.lastPathComponent)")
    } catch {
        print("⚠️ Could not clear \(directory.lastPathComponent): \(error)")
    }
}

// MARK: - UIView Extension for Gradient with Top Corners Only
extension UIView {
    func applyGradientToTopView(
        colors: [UIColor],
        cornerRadius: CGFloat = 18,
        startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint = CGPoint(x: 1, y: 0.5)
    ) {
        self.layoutIfNeeded()
        
        // Remove any existing gradient layers
        self.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = self.bounds
        
        // Create mask path that only rounds top corners
        let maskPath = UIBezierPath()
        let bounds = self.bounds
        
        // Start from top-left (after rounded corner)
        maskPath.move(to: CGPoint(x: cornerRadius, y: 0))
        // Top edge
        maskPath.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: 0))
        // Top-right rounded corner
        maskPath.addArc(withCenter: CGPoint(x: bounds.width - cornerRadius, y: cornerRadius),
                        radius: cornerRadius,
                        startAngle: -CGFloat.pi / 2,
                        endAngle: 0,
                        clockwise: true)
        // Right edge
        maskPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        // Bottom edge
        maskPath.addLine(to: CGPoint(x: 0, y: bounds.height))
        // Left edge
        maskPath.addLine(to: CGPoint(x: 0, y: cornerRadius))
        // Top-left rounded corner
        maskPath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                        radius: cornerRadius,
                        startAngle: CGFloat.pi,
                        endAngle: -CGFloat.pi / 2,
                        clockwise: true)
        maskPath.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        gradientLayer.mask = maskLayer
        
        self.layer.insertSublayer(gradientLayer, at: 0)
        self.backgroundColor = .clear
    }
    
    func updateTopViewGradientMask(cornerRadius: CGFloat = 18) {
        // Update gradient layer mask if it exists
        if let gradientLayer = self.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = self.bounds
            
            let bounds = self.bounds
            
            let maskPath = UIBezierPath()
            maskPath.move(to: CGPoint(x: cornerRadius, y: 0))
            maskPath.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: 0))
            maskPath.addArc(withCenter: CGPoint(x: bounds.width - cornerRadius, y: cornerRadius),
                            radius: cornerRadius,
                            startAngle: -CGFloat.pi / 2,
                            endAngle: 0,
                            clockwise: true)
            maskPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            maskPath.addLine(to: CGPoint(x: 0, y: bounds.height))
            maskPath.addLine(to: CGPoint(x: 0, y: cornerRadius))
            maskPath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                            radius: cornerRadius,
                            startAngle: CGFloat.pi,
                            endAngle: -CGFloat.pi / 2,
                            clockwise: true)
            maskPath.close()
            
            if let maskLayer = gradientLayer.mask as? CAShapeLayer {
                maskLayer.path = maskPath.cgPath
            }
        }
    }
}

func applyTopCornerRadiusMask(to view: UIView, cornerRadius: CGFloat) {
    view.layoutIfNeeded()
    
    let maskPath = UIBezierPath()
    let bounds = view.bounds
    
    // Start from top-left (after rounded corner)
    maskPath.move(to: CGPoint(x: cornerRadius, y: 0))
    // Top edge
    maskPath.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: 0))
    // Top-right rounded corner
    maskPath.addArc(withCenter: CGPoint(x: bounds.width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: -CGFloat.pi / 2,
                    endAngle: 0,
                    clockwise: true)
    // Right edge
    maskPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
    // Bottom edge
    maskPath.addLine(to: CGPoint(x: 0, y: bounds.height))
    // Left edge
    maskPath.addLine(to: CGPoint(x: 0, y: cornerRadius))
    // Top-left rounded corner
    maskPath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat.pi,
                    endAngle: -CGFloat.pi / 2,
                    clockwise: true)
    maskPath.close()
    
    let maskLayer = CAShapeLayer()
    maskLayer.path = maskPath.cgPath
    view.layer.mask = maskLayer
}

func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized || status == .limited else {
            completion(false, NSError(domain: "PermissionDenied", code: 1, userInfo: nil))
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            completion(success, error)
        }
    }
}

func setHTMLTextWithCustomFont(_ html: String, label: UILabel, font: UIFont) {

    let styledHTML = """
    <style>
    body {
        font-family: '\(font.fontName)';
        font-size: \(font.pointSize)px;
    }
    </style>
    \(html)
    """

    guard let data = styledHTML.data(using: .utf8) else { return }

    let attributedString = try? NSAttributedString(
        data: data,
        options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ],
        documentAttributes: nil
    )

    label.attributedText = attributedString
    label.textAlignment = .center
}
