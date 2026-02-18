import UIKit

final class TriangleGradientView: UIView {

    // Public config
    var triangleHeight: CGFloat = 70 {
        didSet { setNeedsLayout() }
    }

    var cornerRadius: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    var startColor: UIColor = .systemPink {
        didSet { updateGradient() }
    }

    var endColor: UIColor = .systemOrange {
        didSet { updateGradient() }
    }

    // Layers
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)

        layer.addSublayer(gradientLayer)
        gradientLayer.mask = shapeLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
        updatePath()
        updateGradient()
    }

    private func updateGradient() {
        gradientLayer.colors = [
            startColor.cgColor,
            endColor.cgColor
        ]
    }

    private func updatePath() {
        let w = bounds.width
        let h = bounds.height

        guard w > 0, h > 0 else { return }

        let path = UIBezierPath()

        // Top-left
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        if cornerRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: 0),
                controlPoint: CGPoint(x: 0, y: 0)
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }

        // Top edge
        path.addLine(to: CGPoint(x: w - cornerRadius, y: 0))

        // Top-right
        if cornerRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: w, y: cornerRadius),
                controlPoint: CGPoint(x: w, y: 0)
            )
        } else {
            path.addLine(to: CGPoint(x: w, y: 0))
        }

        // Right side
        path.addLine(to: CGPoint(x: w, y: h - triangleHeight))

        // Triangle point
        path.addLine(to: CGPoint(x: w / 2, y: h))

        // Left triangle side
        path.addLine(to: CGPoint(x: 0, y: h - triangleHeight))

        path.close()

        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.black.cgColor // REQUIRED for mask
    }
}
