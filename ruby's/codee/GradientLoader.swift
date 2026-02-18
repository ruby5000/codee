import UIKit

class GradientLoader: UIView {
    
    private let backgroundView = UIView()
    private let loaderContainer = UIView()
    
    private let baseRing = CAShapeLayer()       // full ring
    private let progressLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let rotatingContainer = CALayer()
    
    private var isAnimating = false
    private let rotationKey = "rotationAnimation"
    
    // Force dark mode colors regardless of system theme
    var forceDarkMode: Bool = false {
        didSet {
            updateColors()
            // Force layout update to apply new trait collection
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    // Override trait collection to force dark mode when forceDarkMode is enabled
    override var traitCollection: UITraitCollection {
        if forceDarkMode {
            return UITraitCollection(traitsFrom: [
                super.traitCollection,
                UITraitCollection(userInterfaceStyle: .dark)
            ])
        }
        return super.traitCollection
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()     
        backgroundView.frame = bounds
        loaderContainer.center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Update colors when layout changes to ensure dark mode colors are applied
        if forceDarkMode {
            updateColors()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // Update colors when added to view hierarchy to ensure proper trait collection
        if forceDarkMode {
            updateColors()
        }
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        // Default: do not intercept touches unless actively animating
        self.isUserInteractionEnabled = false
        
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3) // Reduced from 0.6 to 0.3 for lighter background
        addSubview(backgroundView)
        
        loaderContainer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        loaderContainer.center = center
        loaderContainer.layer.cornerRadius = 20
        backgroundView.addSubview(loaderContainer)
        
        setupLoader(in: loaderContainer.bounds)
        updateColors()   // initial dynamic colors
    }

    private func setupLoader(in rect: CGRect) {
        let lineWidth: CGFloat = 7
        let radius = min(rect.width, rect.height) / 2 - lineWidth - 22
        
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 1.5 * CGFloat.pi,
            clockwise: true
        )
        
        // Base full ring
        baseRing.path = circularPath.cgPath
        baseRing.lineWidth = lineWidth
        baseRing.fillColor = UIColor.clear.cgColor
        loaderContainer.layer.addSublayer(baseRing)
        
        // Rotating container
        rotatingContainer.frame = rect
        loaderContainer.layer.addSublayer(rotatingContainer)
        
        // Progress arc (mask for gradient)
        progressLayer.path = circularPath.cgPath
        progressLayer.lineWidth = lineWidth
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = 0.25
        progressLayer.strokeColor = UIColor.black.cgColor
        
        // Gradient
        gradientLayer.frame = rect
        gradientLayer.colors = [
            UIColor.systemRed.cgColor,
            UIColor.systemOrange.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.mask = progressLayer
        rotatingContainer.addSublayer(gradientLayer)
    }
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        // Intercept touches while visible/loading
        self.isUserInteractionEnabled = true
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * CGFloat.pi
        rotation.duration = 1.2
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        rotatingContainer.add(rotation, forKey: rotationKey)
    }
    
    func forceRestartAnimating() {
        // Force reset state and restart animation (useful after app returns from background)
        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        rotatingContainer.transform = CATransform3DIdentity
        // Don't remove layers or hide - just reset animation state
        startAnimating()
    }
    
    func stopAnimating() {
        isAnimating = false
        rotatingContainer.removeAllAnimations()
        rotatingContainer.removeAnimation(forKey: rotationKey)
        rotatingContainer.transform = CATransform3DIdentity
        // Allow touches to pass through if this view remains
        self.isUserInteractionEnabled = false
    }

    // Pass-through touches when not animating; only block when actively loading
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return isAnimating ? super.point(inside: point, with: event) : false
    }
    
    // 🔑 Unified update method
    private func updateColors() {
        // Create a dark mode trait collection when forceDarkMode is enabled
        let colorTraitCollection: UITraitCollection
        if forceDarkMode {
            // Force dark mode by creating a trait collection with dark user interface style
            colorTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .dark)
            ])
        } else {
            colorTraitCollection = traitCollection
        }
        
        // Resolve colors with the appropriate trait collection
        baseRing.strokeColor = UIColor(
            named: "APP_BG_THEME_COLOR",
            in: .main,
            compatibleWith: colorTraitCollection
        )?.cgColor
        
        loaderContainer.backgroundColor = UIColor(
            named: "CENTER_LOADER_BG",
            in: .main,
            compatibleWith: colorTraitCollection
        )
    }
    
    // 🔑 Single override
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Only update colors if not forcing dark mode, or if forceDarkMode was just enabled
        if !forceDarkMode && traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        } else if forceDarkMode {
            // Always update when forcing dark mode to ensure colors are correct
            updateColors()
        }
    }
}

class GradientButtonLoader: UIView {
    
    private let baseRing = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let rotatingContainer = CALayer()
    
    var isAnimating = false
    private let rotationKey = "rotationAnimation"
    
    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        isHidden = true   // 🔑 keep hidden until start called
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isAnimating {
            setupLayers() // rebuild if size changed
        }
    }
    
    // MARK: - Setup Layers
    private func setupLayers() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let lineWidth: CGFloat = 4
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        
        // 🔹 Base ring (outer background ring)
        baseRing.path = circlePath.cgPath
        baseRing.strokeColor = UIColor(named: "LOADER_BG_RING")?.cgColor ?? UIColor.systemGray.cgColor
        baseRing.fillColor = UIColor.clear.cgColor
        baseRing.lineWidth = lineWidth
        baseRing.lineCap = .round
        layer.addSublayer(baseRing)
        
        // 🔹 Progress ring (inner colored ring)
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeColor = UIColor(named: "LIGHT_RED")?.cgColor ?? UIColor.systemRed.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0.25 // only a slice
        progressLayer.lineCap = .round
        
        rotatingContainer.frame = bounds
        rotatingContainer.addSublayer(progressLayer)
        layer.addSublayer(rotatingContainer)
    }
    
    // MARK: - Animations
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        isHidden = false
        setupLayers()
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1.2
        rotation.repeatCount = .infinity
        rotatingContainer.add(rotation, forKey: rotationKey)
    }
    
    func forceRestartAnimating() {
        // Force reset state and restart animation (useful after app returns from background)
        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        // Don't remove layers or hide - just reset animation state
        startAnimating()
    }
    
    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        isHidden = true
    }
}

class OrangeButtonLoader: UIView {
    
    private let baseRing = CAShapeLayer()
    private let progressRing = CAShapeLayer()
    private let rotatingLayer = CALayer()
    
    private var isAnimating = false
    private let rotationKey = "rotationAnimation"
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLoader()
        isHidden = true // ✅ Hide until explicitly started
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoader()
        isHidden = true // ✅ Hide until explicitly started
    }
    
    // MARK: - Setup
    private func setupLoader() {
        backgroundColor = .clear
        
        let lineWidth: CGFloat = 4
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Base ring (white)
        let basePath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        baseRing.path = basePath.cgPath
        baseRing.lineWidth = lineWidth
        baseRing.strokeColor = UIColor.white.cgColor
        baseRing.fillColor = UIColor.clear.cgColor
        layer.addSublayer(baseRing)
        
        // Progress ring (black)
        progressRing.path = basePath.cgPath
        progressRing.lineWidth = lineWidth
        progressRing.strokeColor = UIColor.black.cgColor
        progressRing.fillColor = UIColor.clear.cgColor
        progressRing.strokeEnd = 0.25 // small arc
        progressRing.lineCap = .round
        
        rotatingLayer.frame = bounds
        rotatingLayer.addSublayer(progressRing)
        layer.addSublayer(rotatingLayer)
    }
    
    // MARK: - Public Controls
    func startAnimating() {
        guard !isAnimating else { return }
        isHidden = false
        isAnimating = true
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        rotatingLayer.add(rotation, forKey: rotationKey)
    }
    
    func stopAnimating() {
        isAnimating = false
        rotatingLayer.removeAnimation(forKey: rotationKey)
        isHidden = true
    }
}

class CopyLoader: UIView {
    
    private let baseRing = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let rotatingContainer = CALayer()
    
    var isAnimating = false
    private let rotationKey = "rotationAnimation"
    
    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        isHidden = true   // 🔑 keep hidden until start called
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isAnimating {
            setupLayers() // rebuild if size changed
        }
    }
    
    // MARK: - Setup Layers
    private func setupLayers() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let lineWidth: CGFloat = 4
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        
        // 🔹 Base ring (outer background ring)
        baseRing.path = circlePath.cgPath
        baseRing.strokeColor = UIColor(named: "COPY_LOADER_BG")?.cgColor ?? UIColor.systemGray.cgColor
        baseRing.fillColor = UIColor.clear.cgColor
        baseRing.lineWidth = lineWidth
        baseRing.lineCap = .round
        layer.addSublayer(baseRing)
        
        // 🔹 Progress ring (inner colored ring)
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeColor = UIColor(named: "COPY_LOADER")?.cgColor ?? UIColor.systemRed.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0.25 // only a slice
        progressLayer.lineCap = .round
        
        rotatingContainer.frame = bounds
        rotatingContainer.addSublayer(progressLayer)
        layer.addSublayer(rotatingContainer)
    }
    
    // MARK: - Animations
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        isHidden = false
        setupLayers()
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1.2
        rotation.repeatCount = .infinity
        rotatingContainer.add(rotation, forKey: rotationKey)
    }
    
    func forceRestartAnimating() {
        // Force reset state and restart animation (useful after app returns from background)
        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        // Don't remove layers or hide - just reset animation state
        startAnimating()
    }
    
    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        isHidden = true
    }
}

final class ShareBtnLoader: UIView {

    // MARK: - Public Configurable Properties
    var backgroundRingColor: UIColor = .systemGray {
        didSet {
            baseRing.strokeColor = backgroundRingColor.cgColor
        }
    }

    var progressRingColor: UIColor = .systemRed {
        didSet {
            progressLayer.strokeColor = progressRingColor.cgColor
        }
    }

    var ringLineWidth: CGFloat = 4 {
        didSet {
            rebuildIfNeeded()
        }
    }

    // MARK: - Private Layers
    private let baseRing = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let rotatingContainer = CALayer()

    private let rotationKey = "rotationAnimation"
    private(set) var isAnimating = false

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        isHidden = true
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isAnimating {
            setupLayers()
        }
    }

    // MARK: - Layer Setup
    private func rebuildIfNeeded() {
        if isAnimating {
            setupLayers()
        }
    }

    private func setupLayers() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let radius = min(bounds.width, bounds.height) / 2 - ringLineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )

        // 🔹 Background Ring
        baseRing.path = circlePath.cgPath
        baseRing.strokeColor = UIColor.white.cgColor
        baseRing.fillColor = UIColor.clear.cgColor
        baseRing.lineWidth = ringLineWidth
        baseRing.lineCap = .round
        layer.addSublayer(baseRing)

        // 🔹 Progress Ring
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeColor = progressRingColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = ringLineWidth
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0.25
        progressLayer.lineCap = .round

        rotatingContainer.frame = bounds
        rotatingContainer.addSublayer(progressLayer)
        layer.addSublayer(rotatingContainer)
    }

    // MARK: - Animations
    func startAnimating() {
        guard !isAnimating else { return }

        isAnimating = true
        isHidden = false
        setupLayers()

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1.2
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false

        rotatingContainer.add(rotation, forKey: rotationKey)
    }

    func forceRestartAnimating() {
        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        startAnimating()
    }

    func stopAnimating() {
        guard isAnimating else { return }

        isAnimating = false
        rotatingContainer.removeAnimation(forKey: rotationKey)
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        isHidden = true
    }
}
