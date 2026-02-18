import UIKit

class StaticAudioWaveView: UIView {

    var totalBars: Int = 30 {
        didSet {
            setupInitialHeights()
            setNeedsDisplay()
        }
    }

    var completedBars: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var barColorPlayed: UIColor = .APP_GREDIENT_END {
        didSet {
            setNeedsDisplay()
        }
    }

    var barColorUnplayed: UIColor = .lightGray {
        didSet {
            setNeedsDisplay()
        }
    }

    var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                resume()
            } else {
                pause()
            }
        }
    }

    private var timer: Timer?
    private var barHeights: [CGFloat] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialHeights()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupInitialHeights()
    }

    private func setupInitialHeights() {
        barHeights = (0..<totalBars).map { _ in CGFloat.random(in: 0.4...1.0) }
    }

    func start() {
        completedBars = 0
        resume()
    }

    private func resume() {
        guard timer == nil else { return }

        // Get actual duration from parent view controller if possible
        let totalDuration: TimeInterval
        if let parentVC = self.findViewController() as? InboxPreviewVC {
            totalDuration = parentVC.audioDuration
        } else if let parentVC5 = self.findViewController() as? InboxPreview_5VC {
            totalDuration = parentVC5.audioDuration
        } else {
            totalDuration = 10.0 // fallback
        }
        
        let intervalPerBar = totalDuration / Double(totalBars)

        timer = Timer.scheduledTimer(withTimeInterval: intervalPerBar, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.completedBars += 1
            if self.completedBars >= self.totalBars {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // Add timer to common run loop modes to ensure it continues during scrolling
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
    }

    // ✅ Enhanced reset method that properly resets everything
    func reset() {
        // Stop the timer
        pause()
        
        // Reset completed bars to 0
        completedBars = 0
        
        // Reset isPlaying state
        isPlaying = false
        
        // Generate new random heights for visual variety (optional)
        setupInitialHeights()
        
        // Force a visual update
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }
    
    // ✅ Reset waveform but keep the same bar heights (for restarting)
    func resetWaveformKeepHeights() {
        // Stop the timer
        pause()
        
        // Reset completed bars to 0
        completedBars = 0
        
        // Reset isPlaying state
        isPlaying = false
        
        // DON'T regenerate heights - keep the same pattern
        
        // Force a visual update
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }
    
    // ✅ Additional method for complete reset with new random heights
    func resetWaveform() {
        reset()
    }

    override func draw(_ rect: CGRect) {
        guard totalBars > 0 else { return }

        let context = UIGraphicsGetCurrentContext()
        context?.clear(rect)

        let barWidth: CGFloat = rect.width / CGFloat(totalBars) * 0.6
        let spacing: CGFloat = (rect.width - CGFloat(totalBars) * barWidth) / CGFloat(max(1, totalBars - 1))

        for i in 0..<totalBars {
            let x = CGFloat(i) * (barWidth + spacing)
            let normalizedHeight = barHeights.indices.contains(i) ? barHeights[i] : 0.5
            let barHeight = rect.height * normalizedHeight
            let y = (rect.height - barHeight) / 2

            let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: barWidth, height: barHeight), cornerRadius: barWidth / 2)
            let color = (i < completedBars) ? barColorPlayed : barColorUnplayed
            color.setFill()
            path.fill()
        }
    }

    deinit {
        pause()
    }
}
