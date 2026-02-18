import UIKit

class CommonShimmerView: UIView {
    
    // MARK: - Properties
    private let containerView = UIView()
    private let firstView = ShimmerView()
    private let secondView = ShimmerView()
    private let thirdView = ShimmerView()
    
    private var isAnimating = false
    
    // MARK: - Constants
    private var firstViewHeight: CGFloat = 150
    private var secondViewHeight: CGFloat = 100
    private var thirdViewHeight: CGFloat = 100
    private let spacing: CGFloat = 20
    private let cornerRadius: CGFloat = 8
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear
        
        // Adjust heights based on device size
        adjustHeightsForDevice()
        
        // Container view setup
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        addSubview(containerView)
        
        // First view setup (150 height)
        firstView.translatesAutoresizingMaskIntoConstraints = false
        firstView.layer.cornerRadius = cornerRadius
        firstView.clipsToBounds = true
        containerView.addSubview(firstView)
        
        // Second view setup (100 height)
        secondView.translatesAutoresizingMaskIntoConstraints = false
        secondView.layer.cornerRadius = cornerRadius
        secondView.clipsToBounds = true
        containerView.addSubview(secondView)
        
        // Third view setup (100 height)
        thirdView.translatesAutoresizingMaskIntoConstraints = false
        thirdView.layer.cornerRadius = cornerRadius
        thirdView.clipsToBounds = true
        containerView.addSubview(thirdView)
        
        setupConstraints()
    }
    
    // MARK: - Device Responsiveness
    private func adjustHeightsForDevice() {
        let screenHeight = UIScreen.main.bounds.height
        
        if isSmallDevice() {
            // Small devices (iPhone SE, etc.)
            firstViewHeight = 120
            secondViewHeight = 80
            thirdViewHeight = 80
        } else if screenHeight > 800 {
            // Large devices (iPhone Pro Max, iPad, etc.)
            firstViewHeight = 180
            secondViewHeight = 120
            thirdViewHeight = 120
        } else {
            // Standard devices (iPhone 12, 13, 14, etc.)
            firstViewHeight = 150
            secondViewHeight = 100
            thirdViewHeight = 100
        }
    }
    
    private func isSmallDevice() -> Bool {
        let screenHeight = UIScreen.main.bounds.height
        return screenHeight <= 667 // iPhone SE, iPhone 8, etc.
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // First view constraints (150 height)
            firstView.topAnchor.constraint(equalTo: containerView.topAnchor),
            firstView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            firstView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            firstView.heightAnchor.constraint(equalToConstant: firstViewHeight),
            
            // Second view constraints (100 height)
            secondView.topAnchor.constraint(equalTo: firstView.bottomAnchor, constant: spacing),
            secondView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            secondView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            secondView.heightAnchor.constraint(equalToConstant: secondViewHeight),
            
            // Third view constraints (100 height)
            thirdView.topAnchor.constraint(equalTo: secondView.bottomAnchor, constant: spacing),
            thirdView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            thirdView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            thirdView.heightAnchor.constraint(equalToConstant: thirdViewHeight),
            thirdView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func startShimmerAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        firstView.startAnimating()
        secondView.startAnimating()
        thirdView.startAnimating()
    }
    
    func stopShimmerAnimation() {
        guard isAnimating else { return }
        isAnimating = false
        
        firstView.stopAnimating()
        secondView.stopAnimating()
        thirdView.stopAnimating()
    }
    
    func showShimmerEffect() {
        isHidden = false
        startShimmerAnimation()
    }
    
    func hideShimmerEffect() {
        isHidden = true
        stopShimmerAnimation()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure shimmer views are properly sized
        firstView.layoutIfNeeded()
        secondView.layoutIfNeeded()
        thirdView.layoutIfNeeded()
    }
    
    // MARK: - Cleanup
    deinit {
        stopShimmerAnimation()
    }
}

// MARK: - Convenience Extension for UIView
extension UIView {
    
    /// Add shimmer effect to any UIView with the specified layout
    /// - Parameters:
    ///   - firstHeight: Height of the first shimmer view (default: 100)
    ///   - spacing: Spacing between views (default: 20)
    ///   - cornerRadius: Corner radius for shimmer views (default: 8)
    /// - Returns: The CommonShimmerView instance
    @discardableResult
    func addShimmerEffect(firstHeight: CGFloat = 100, spacing: CGFloat = 20, cornerRadius: CGFloat = 10) -> CommonShimmerView {
        // Remove existing shimmer if any
        removeShimmerEffect()
        
        let shimmerView = CommonShimmerView()
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        // Ensure shimmer view has proper background to cover content
        shimmerView.backgroundColor = backgroundColor ?? .systemBackground
        addSubview(shimmerView)
        
        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        shimmerView.tag = 999888 // Unique tag for identification
        return shimmerView
    }
    
    /// Remove shimmer effect from the view
    func removeShimmerEffect() {
        if let shimmerView = viewWithTag(999888) as? CommonShimmerView {
            shimmerView.stopShimmerAnimation()
            shimmerView.removeFromSuperview()
        }
    }
    
    /// Show shimmer effect
    func showShimmer() {
        if let shimmerView = viewWithTag(999888) as? CommonShimmerView {
            shimmerView.showShimmerEffect()
        }
    }
    
    /// Hide shimmer effect
    func hideShimmer() {
        if let shimmerView = viewWithTag(999888) as? CommonShimmerView {
            shimmerView.hideShimmerEffect()
        }
    }
}
