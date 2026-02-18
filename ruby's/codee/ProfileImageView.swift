import UIKit
import SDWebImage

class ProfileImageView: UIView {
    
    // MARK: - UI Components
    private let backgroundBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill // Fill the circle
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white // Preserve white background from original image
        imageView.layer.cornerRadius = 120 // Will be set to half the size
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private var isAnimating = false
    private var dismissCompletion: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        // Add subviews
        addSubview(backgroundBlurView)
        addSubview(profileImageView)
        addSubview(loadingIndicator)
        
        // Setup constraints
        setupConstraints()
        
        // Setup tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundBlurView.addGestureRecognizer(tapGesture)
        
        // Initial state - blur visible, image hidden
        backgroundBlurView.alpha = 1.0
        profileImageView.alpha = 0
        profileImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background blur view
            backgroundBlurView.topAnchor.constraint(equalTo: topAnchor),
            backgroundBlurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Profile image view (centered)
            profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 240),
            profileImageView.heightAnchor.constraint(equalToConstant: 240),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func showProfileImage(imageURL: String?, completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        dismissCompletion = completion
        
        // Show loading indicator
        loadingIndicator.startAnimating()
        
        // Load image if URL provided
        if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
            profileImageView.sd_setImage(with: url) { [weak self] image, error, cacheType, imageURL in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    if let error = error {
                        print("❌ Error loading profile image: \(error.localizedDescription)")
                        // Set default image or placeholder
                        self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                        self?.profileImageView.tintColor = .systemGray
                    } else {
                        print("✅ Profile image loaded successfully")
                    }
                }
            }
        } else {
            // No URL provided, use default image
            loadingIndicator.stopAnimating()
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray
        }
        
        // Animate in
        animateIn()
    }
    
    func showProfileImage(image: UIImage?, completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        dismissCompletion = completion
        
        // Set image directly
        profileImageView.image = image ?? UIImage(systemName: "person.circle.fill")
        if image == nil {
            profileImageView.tintColor = .systemGray
        }
        
        // Animate in
        animateIn()
    }
    
    // MARK: - Animations
    private func animateIn() {
        // Haptic feedback
        HapticManager.trigger(.light)
        
        // Only animate the profile image - blur background is already visible
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.profileImageView.alpha = 1.0
                self.profileImageView.transform = .identity
            },
            completion: { _ in
                self.isAnimating = false
            }
        )
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Haptic feedback
        HapticManager.trigger(.light)
        
        // Animate both image and blur background out at the same time
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseIn, .allowUserInteraction],
            animations: {
                // Animate both image and blur together
                self.profileImageView.alpha = 0.0
                self.profileImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.backgroundBlurView.alpha = 0.0
            },
            completion: { _ in
                self.isAnimating = false
                completion()
            }
        )
    }
    
    // MARK: - Actions
    @objc private func backgroundTapped() {
        dismiss()
    }
    
    func dismiss() {
        animateOut { [weak self] in
            self?.removeFromSuperview()
            self?.dismissCompletion?()
        }
    }
}

// MARK: - Convenience Extension
extension ProfileImageView {
    
    /// Show profile image view with URL
    static func show(in view: UIView, imageURL: String?, completion: (() -> Void)? = nil) {
        let profileView = ProfileImageView()
        profileView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileView)
        
        // Pin to edges
        NSLayoutConstraint.activate([
            profileView.topAnchor.constraint(equalTo: view.topAnchor),
            profileView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Show with animation
        profileView.showProfileImage(imageURL: imageURL, completion: completion)
    }
    
    /// Show profile image view with UIImage
    static func show(in view: UIView, image: UIImage?, completion: (() -> Void)? = nil) {
        let profileView = ProfileImageView()
        profileView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileView)
        
        // Pin to edges
        NSLayoutConstraint.activate([
            profileView.topAnchor.constraint(equalTo: view.topAnchor),
            profileView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Show with animation
        profileView.showProfileImage(image: image, completion: completion)
    }
}
