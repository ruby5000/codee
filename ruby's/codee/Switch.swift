import UIKit

class CustomSwitch: UIControl {
    
    private let backgroundView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let circleView = UIView()
    private var iconImageViews: [UIImageView] = []
    
    private let circleSize: CGFloat = 45
    private let circleImageSize: CGFloat = 30
    private let iconNames = ["1", "2", "3", "4"]
    
    private(set) var selectedIndex: Int = 0
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        self.clipsToBounds = true
        
        // Gradient background
        gradientLayer.colors = [
            UIColor(red: 250/255, green: 73/255, blue: 87/255, alpha: 1).cgColor,
            UIColor(red: 253/255, green: 126/255, blue: 65/255, alpha: 1).cgColor
        ]
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        addSubview(backgroundView)
        
        // Circle view
        circleView.backgroundColor = .white
        circleView.layer.masksToBounds = true
        addSubview(circleView)
        
        // Icons
        for name in iconNames {
            let imageView = UIImageView(image: UIImage(named: name))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .white
            addSubview(imageView)
            iconImageViews.append(imageView)
        }
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Round corners based on actual height
        self.layer.cornerRadius = bounds.height / 2
        
        // Background frame
        backgroundView.frame = bounds
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height / 2
        
        // Circle view frame
        let newX = positionFor(index: selectedIndex)
        circleView.frame = CGRect(
            x: newX,
            y: (bounds.height - circleSize) / 2,
            width: circleSize,
            height: circleSize
        )
        circleView.layer.cornerRadius = circleSize / 2
        
        // Icon positions
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        for (i, imageView) in iconImageViews.enumerated() {
            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: circleImageSize,
                height: circleImageSize
            )
            imageView.center = CGPoint(
                x: segmentWidth * CGFloat(i) + segmentWidth / 2,
                y: bounds.height / 2
            )
        }
    }
    
    // MARK: - Helpers
    private func positionFor(index: Int) -> CGFloat {
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        return segmentWidth * CGFloat(index) + (segmentWidth - circleSize) / 2
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        let index = min(max(Int(location.x / segmentWidth), 0), totalIcons - 1)
        setSelectedIndex(index, animated: true)
    }
    
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()
        feedback.impactOccurred()
        
        let newX = positionFor(index: selectedIndex)
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.5,
                options: .curveEaseInOut,
                animations: {
                    self.circleView.frame.origin.x = newX
                }
            )
        } else {
            circleView.frame.origin.x = newX
        }
        
        sendActions(for: .valueChanged)
    }
}


class CustomSwitchInboxPreview: UIControl {
    
    private let backgroundView = UIView()
    private let glassGradientLayer = CAGradientLayer()
    private let borderGradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()
    private let circleView = UIView()
    
    private let glassBorderWidth: CGFloat = 1.5
    private var iconImageViews: [UIImageView] = []
    
    private let circleSize: CGFloat = 50
    private let circleImageSize: CGFloat = 28
    
    // Configurable WhatsApp icon name (default for InboxPreview_3VC and InboxPreviewVC)
    var whatsappIconName: String = "whatsappt_icon_reply" {
        didSet {
            updateWhatsAppIcon()
        }
    }
    
    private var iconNames: [String] {
        return [
            "instagram_icon_reply",
            "snapchat_icon_reply",
            whatsappIconName,
            "tiktok_icon_reply"
        ]
    }
    
    private(set) var selectedIndex: Int = 0
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        clipsToBounds = true
        
        // Glass effect: gradient + border (light/dark set in updateGlassColorsForAppearance)
        backgroundView.layer.masksToBounds = true
        glassGradientLayer.locations = [0, 0.5, 1]
        backgroundView.layer.insertSublayer(glassGradientLayer, at: 0)
        borderGradientLayer.locations = [0, 0.5, 1]
        borderMaskLayer.fillColor = nil
        borderMaskLayer.strokeColor = UIColor.black.cgColor
        borderMaskLayer.lineWidth = glassBorderWidth
        borderGradientLayer.mask = borderMaskLayer
        backgroundView.layer.addSublayer(borderGradientLayer)
        addSubview(backgroundView)
        
        // Circle (indicator) — will be sized/positioned in layoutSubviews
        circleView.backgroundColor = .CIRCULER_BG_BORDER
        circleView.layer.masksToBounds = true
        addSubview(circleView) // Added before icons
        
        // Icons
        for iconName in iconNames {
            let imageView = UIImageView(image: UIImage(named: iconName))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .white
            addSubview(imageView) // Above circle
            iconImageViews.append(imageView)
        }
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        updateGlassColorsForAppearance()
    }
    
    // MARK: - Light / Dark appearance
    private func updateGlassColorsForAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if isDark {
            // Dark: darker gray gradient (frosted glass on dark bg)
            glassGradientLayer.colors = [
                UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1).cgColor,
                UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1).cgColor
            ]
            // Dark border: subtle light top edge → darker bottom (glass rim)
            borderGradientLayer.colors = [
                UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 0.7).cgColor,
                UIColor(red: 0.38, green: 0.38, blue: 0.42, alpha: 0.6).cgColor,
                UIColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 0.5).cgColor
            ]
        } else {
            // Light: existing glass gradient
            glassGradientLayer.colors = [
                UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1).cgColor,
                UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1).cgColor,
                UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1).cgColor
            ]
            borderGradientLayer.colors = [
                UIColor(red: 1, green: 1, blue: 1, alpha: 0.9).cgColor,
                UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.9).cgColor,
                UIColor(red: 0.82, green: 0.82, blue: 0.86, alpha: 0.85).cgColor
            ]
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateGlassColorsForAppearance()
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Round background based on actual height
        layer.cornerRadius = bounds.height / 2
        
        // Match background frame and glass gradient
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = bounds.height / 2
        glassGradientLayer.frame = bounds
        glassGradientLayer.cornerRadius = bounds.height / 2
        // Gradient border (glass rim): frame + mask stroke
        borderGradientLayer.frame = bounds
        borderGradientLayer.cornerRadius = bounds.height / 2
        borderMaskLayer.frame = bounds
        borderMaskLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2).cgPath
        borderMaskLayer.lineWidth = glassBorderWidth
        
        // Circle frame based on selectedIndex
        let newX = positionFor(index: selectedIndex)
        circleView.frame = CGRect(
            x: newX,
            y: (bounds.height - circleSize) / 2,
            width: circleSize,
            height: circleSize
        )
        circleView.layer.cornerRadius = circleSize / 2
        
        // Icon positions
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        for (i, imageView) in iconImageViews.enumerated() {
            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: circleImageSize,
                height: circleImageSize
            )
            imageView.center = CGPoint(
                x: segmentWidth * CGFloat(i) + segmentWidth / 2,
                y: bounds.height / 2
            )
        }
    }
    
    // MARK: - Helpers
    private func positionFor(index: Int) -> CGFloat {
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        return segmentWidth * CGFloat(index) + (segmentWidth - circleSize) / 2
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        let index = min(max(Int(location.x / segmentWidth), 0), totalIcons - 1)
        setSelectedIndex(index, animated: true)
    }
    
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()
        feedback.impactOccurred()
        
        let newX = positionFor(index: selectedIndex)
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.5,
                options: .curveEaseInOut,
                animations: {
                    self.circleView.frame.origin.x = newX
                }
            )
        } else {
            circleView.frame.origin.x = newX
        }
        
        sendActions(for: .valueChanged)
    }
    
    // MARK: - WhatsApp Icon Update
    private func updateWhatsAppIcon() {
        // WhatsApp icon is at index 2
        guard iconImageViews.count > 2 else { return }
        iconImageViews[2].image = UIImage(named: whatsappIconName)
    }
}


class CustomSwitchShareBottom: UIControl {
    
    private let backgroundView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let circleView = UIView()
    private var iconImageViews: [UIImageView] = []
    
    private let circleSize: CGFloat = 45
    private let circleImageSize: CGFloat = 30
    private let iconNames = ["1", "2", "3", "4"]
    
    private(set) var selectedIndex: Int = 0
    private var gameType: Int = 0 // 0 = default, 1 = Game1, 2 = Game2
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        self.clipsToBounds = false // Allow shadow to be visible
        
        // Gradient background
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.cgColor,
        ]
        gradientLayer.borderColor = UIColor.lightGray.cgColor
        gradientLayer.borderWidth = 1
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        addSubview(backgroundView)
        
        // Add shadow to background view
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowRadius = 4
        backgroundView.layer.shadowOpacity = 0.1
        
        // Circle view
        circleView.backgroundColor = .CIRCULER_BG
        circleView.layer.masksToBounds = true
        addSubview(circleView)
        
        // Icons
        for name in iconNames {
            let imageView = UIImageView(image: UIImage(named: name))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .white
            addSubview(imageView)
            iconImageViews.append(imageView)
        }
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // Update colors based on current appearance
        updateColorsForCurrentAppearance()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Round corners based on actual height
        self.layer.cornerRadius = bounds.height / 2
        
        // Background frame
        backgroundView.frame = bounds
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height / 2
        
        // Update shadow path for better performance
        backgroundView.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2).cgPath
        
        // Circle view frame
        let newX = positionFor(index: selectedIndex)
        circleView.frame = CGRect(
            x: newX,
            y: (bounds.height - circleSize) / 2,
            width: circleSize,
            height: circleSize
        )
        circleView.layer.cornerRadius = circleSize / 2
        
        // Icon positions
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        for (i, imageView) in iconImageViews.enumerated() {
            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: circleImageSize,
                height: circleImageSize
            )
            imageView.center = CGPoint(
                x: segmentWidth * CGFloat(i) + segmentWidth / 2,
                y: bounds.height / 2
            )
        }
    }
    
    // MARK: - Helpers
    private func positionFor(index: Int) -> CGFloat {
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        return segmentWidth * CGFloat(index) + (segmentWidth - circleSize) / 2
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let totalIcons = iconNames.count
        let segmentWidth = bounds.width / CGFloat(totalIcons)
        let index = min(max(Int(location.x / segmentWidth), 0), totalIcons - 1)
        setSelectedIndex(index, animated: true)
    }
    
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()
        feedback.impactOccurred()
        
        let newX = positionFor(index: selectedIndex)
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.5,
                options: .curveEaseInOut,
                animations: {
                    self.circleView.frame.origin.x = newX
                }
            )
        } else {
            circleView.frame.origin.x = newX
        }
        
        sendActions(for: .valueChanged)
    }
    
    // MARK: - Game Type Configuration
    func setGameType(_ type: Int) {
        gameType = type
        updateCircleColor()
    }
    
    private func updateCircleColor() {
        switch gameType {
        case 1: // Game 1
            circleView.backgroundColor = .CIRCULER_BG_GAME_1
        case 2: // Game 2
            circleView.backgroundColor = .CIRCULER_BG_GAME_2
        case 3: // Game 3
            circleView.backgroundColor = .CIRCULER_BG_GAME_3
        case 4: // Game 4
            circleView.backgroundColor = .CIRCULER_BG_GAME_4
        case 5: // Game 5
            circleView.backgroundColor = .CIRCULER_BG_GAME_5
        case 6: // Game 5
            circleView.backgroundColor = .CIRCULER_BG_GAME_6
        case 71: // Game 7_Frined
            circleView.backgroundColor = UIColor(named: "CIRCULER_BG_GAME_7_F")
        case 72: // Game 7_Love_Crush
            circleView.backgroundColor = UIColor(named: "CIRCULER_BG_GAME_7_L")
        case 8: // Game 8
            circleView.backgroundColor = UIColor(named: "CIRCULER_BG_GAME_8")
        case 9: // Game 9
            circleView.backgroundColor = UIColor(named: "CIRCULER_BG_GAME_9")
        default: // Default
            circleView.backgroundColor = .CIRCULER_BG
        }
    }
    
    // MARK: - Dark Mode Support
    private func updateColorsForCurrentAppearance() {
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode: #202020 background, no border
            gradientLayer.colors = [
                UIColor(hex: "202020").cgColor,
                UIColor(hex: "202020").cgColor,
            ]
            gradientLayer.borderColor = UIColor.clear.cgColor
            gradientLayer.borderWidth = 0
        } else {
            // Light mode: white background with border
            gradientLayer.colors = [
                UIColor.white.cgColor,
                UIColor.white.cgColor,
            ]
            gradientLayer.borderColor = UIColor.lightGray.cgColor
            gradientLayer.borderWidth = 1
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateColorsForCurrentAppearance()
        }
    }
}
