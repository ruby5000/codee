import UIKit

class CircularProgressBarLayer {
    
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    
    private let duration: TimeInterval = 10
    private var isAnimating = false

    init(in view: UIView) {
        setup(in: view)
    }
    
    private func setup(in view: UIView) {
        let lineWidth: CGFloat = 8
        let radius = min(view.bounds.width, view.bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        
        // Background filled circle
        backgroundLayer.path = circularPath.cgPath
        backgroundLayer.fillColor = UIColor(named: "CIRCULER_BG")?.cgColor
        backgroundLayer.strokeColor = UIColor.clear.cgColor
        view.layer.addSublayer(backgroundLayer)

        // Progress stroke
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor(named: "CIRCULER_BG_BORDER")?.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        view.layer.addSublayer(progressLayer)
    }
    
    func start() {
        guard !isAnimating else { return }
        
        isAnimating = true
        progressLayer.speed = 1
        progressLayer.timeOffset = 0
        progressLayer.beginTime = 0

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.toValue = 1
        anim.duration = duration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        progressLayer.add(anim, forKey: "circularProgress")
    }

    func pause() {
        guard isAnimating else { return }
        isAnimating = false

        let pausedTime = progressLayer.convertTime(CACurrentMediaTime(), from: nil)
        progressLayer.speed = 0
        progressLayer.timeOffset = pausedTime
    }
    
    func resume() {
        guard !isAnimating else { return }
        isAnimating = true

        let pausedTime = progressLayer.timeOffset
        progressLayer.speed = 1
        progressLayer.timeOffset = 0
        progressLayer.beginTime = 0
        let timeSincePause = progressLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        progressLayer.beginTime = timeSincePause
    }

    func updateProgress(_ progress: Float) {
        progressLayer.removeAnimation(forKey: "circularProgress")
        progressLayer.strokeEnd = CGFloat(progress)
    }
    
    func reset() {
        isAnimating = false
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 0
    }
}
