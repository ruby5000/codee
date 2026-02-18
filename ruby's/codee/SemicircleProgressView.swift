import UIKit
import AVFoundation

class SemicircleProgressView: UIView {
    
    // MARK: - Properties
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var progressTimer: Timer?
    private var currentProgress: CGFloat = 0.0
    
    // MARK: - Constants
    private let borderWidth: CGFloat = 4.0
    private let borderColor: UIColor = .black
    private let fillBackgroundColor: UIColor = .white
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupView() {
        self.backgroundColor = .clear
        setupLayers()
    }
    
    private func setupLayers() {
        // Remove existing layers
        backgroundLayer.removeFromSuperlayer()
        progressLayer.removeFromSuperlayer()
        
        // Calculate full circle path
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - borderWidth / 2
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,  // Start from top (12 o'clock)
            endAngle: 1.5 * .pi,   // Full circle
            clockwise: true
        )
        
        // Background layer (white filled circle)
        backgroundLayer.path = circlePath.cgPath
        backgroundLayer.fillColor = fillBackgroundColor.cgColor
        backgroundLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(backgroundLayer)
        
        // Progress layer (black border that fills progressively)
        // This is the border that animates as audio plays
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeColor = borderColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = borderWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0  // Start with no progress
        layer.addSublayer(progressLayer)
        
        // Set initial progress to 0
        updateFillProgress(0.0)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }
    
    // MARK: - Observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioDidStartPlaying),
            name: NSNotification.Name("AudioDidStartPlaying"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioDidPause),
            name: NSNotification.Name("AudioDidPause"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioDidEnd),
            name: NSNotification.Name("AudioDidEnd"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopProgressTimer()
    }
    
    // MARK: - Notification Handlers
    @objc private func handleAudioDidStartPlaying() {
        // Check if audio is starting from beginning or resuming
        if let player = AudioHandler.shared.getPlayer(),
           let currentItem = player.currentItem {
            let currentTime = CMTimeGetSeconds(player.currentTime())
            // If current time is very close to 0, reset progress
            if currentTime < 0.1 {
                reset()
            }
        }
        startProgressTimer()
    }
    
    @objc private func handleAudioDidPause() {
        stopProgressTimer()
    }
    
    @objc private func handleAudioDidEnd() {
        stopProgressTimer()
        // Fill completely when audio ends
        updateFillProgress(1.0)
        // Reset to 0 after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.reset()
        }
    }
    
    // MARK: - Progress Timer
    private func startProgressTimer() {
        stopProgressTimer()
        
        // Use RunLoop to ensure timer runs on main thread
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateProgressFromAudioPlayer()
            }
        }
        RunLoop.current.add(progressTimer!, forMode: .common)
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Progress Update
    private func updateProgressFromAudioPlayer() {
        guard let player = AudioHandler.shared.getPlayer(),
              let currentItem = player.currentItem else {
            return
        }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let duration = CMTimeGetSeconds(currentItem.duration)
        
        guard duration.isFinite && duration > 0 else {
            return
        }
        
        let progress = CGFloat(currentTime / duration)
        updateFillProgress(progress)
    }
    
    private func updateFillProgress(_ progress: CGFloat) {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        // Remove any existing animations to allow smooth updates
        progressLayer.removeAnimation(forKey: "progressAnimation")
        
        // Update stroke end to show progress around the full circle
        // strokeEnd of 0 = no progress, strokeEnd of 1 = full circle
        // Use implicit animation for smooth updates
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        CATransaction.setAnimationDuration(0.1)  // Smooth animation between updates
        progressLayer.strokeEnd = clampedProgress
        CATransaction.commit()
        
        currentProgress = clampedProgress
    }
    
    // MARK: - Public Methods
    func reset() {
        stopProgressTimer()
        currentProgress = 0.0
        updateFillProgress(0.0)
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool = false) {
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = currentProgress
            animation.toValue = progress
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            progressLayer.add(animation, forKey: "progressAnimation")
        }
        updateFillProgress(progress)
    }
}
