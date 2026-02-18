import UIKit
import Lottie

class LottieManager {
    
    private var animationView: LottieAnimationView?
    private var containerView: UIView
    private var animationNames = ["1", "2", "3", "4"]
    private var currentAnimationName: String?
    private var lastPlayedAnimationName: String?
    private var padding: CGFloat = 0

    init(containerView: UIView) {
        self.containerView = containerView
    }
    
    init(containerView: UIView, animationNames: [String], padding: CGFloat = 0) {
        self.containerView = containerView
        self.animationNames = animationNames
        self.padding = padding
    }
    
    /// Helper method to set up constraints with optional padding
    private func setupConstraints(for animationView: LottieAnimationView, in containerView: UIView) {
        if padding > 0 {
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
                animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
                animationView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
                animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
            ])
        } else {
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
    }

    /// Load and play Lottie animation with proper cleanup
    private func loadAndPlayLottie(named name: String, loopMode: LottieLoopMode = .loop, completion: LottieCompletionBlock? = nil) {
        // If the animation is already loaded and playing, return
        if currentAnimationName == name, animationView?.isAnimationPlaying == true {
            return
        }

        // Remove existing animation view
        animationView?.stop()
        animationView?.removeFromSuperview()
        animationView = nil

        // Load new animation efficiently
        guard let animation = LottieAnimation.named(name) else {
            print("❌ Failed to load animation: \(name)")
            return
        }

        let newAnimationView = LottieAnimationView(animation: animation)
        newAnimationView.frame = containerView.bounds
        newAnimationView.contentMode = .scaleAspectFit
        newAnimationView.loopMode = loopMode
        newAnimationView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(newAnimationView)
        setupConstraints(for: newAnimationView, in: containerView)

        newAnimationView.play(completion: completion)
        animationView = newAnimationView
        currentAnimationName = name
    }

    func playRandom() {
        // Don't change animation if one is already playing
        if animationView?.isAnimationPlaying == true {
            return
        }
        
        if let savedName = UserDefaults.standard.string(forKey: "lastLottieName") {
            // Play the same animation as last time
            loadAndPlayLottie(named: savedName)
        } else if let randomName = animationNames.randomElement() {
            // Pick new animation only if no saved one exists
            UserDefaults.standard.set(randomName, forKey: "lastLottieName")
            loadAndPlayLottie(named: randomName)
        }
    }


    func play_SNAPCHAT_lottie() {
        loadAndPlayLottie(named: "SNAPCHAT_PREVIEW")
    }
    
    func playLottie(named name: String, loopMode: LottieLoopMode = .loop, completion: LottieCompletionBlock? = nil) {
        loadAndPlayLottie(named: name, loopMode: loopMode, completion: completion)
    }
    
    func playRandomFromArray(completion: LottieCompletionBlock? = nil) {
        // Don't change animation if one is already playing
        if animationView?.isAnimationPlaying == true {
            return
        }
        
        if let randomName = animationNames.randomElement() {
            lastPlayedAnimationName = randomName
            loadAndPlayLottie(named: randomName, loopMode: .playOnce, completion: completion)
        }
    }
    
    func playRandomConfession(completion: LottieCompletionBlock? = nil) {
        // Filter confession animations (confession_1, confession_2, confession_3)
        let confessionAnimations = animationNames.filter { $0.lowercased().contains("confession") }
        if let randomName = confessionAnimations.randomElement() {
            lastPlayedAnimationName = randomName
            loadAndPlayLottie(named: randomName, loopMode: .playOnce, completion: completion)
        } else if let randomName = animationNames.randomElement() {
            // Fallback to any animation if no confession found
            lastPlayedAnimationName = randomName
            loadAndPlayLottie(named: randomName, loopMode: .playOnce, completion: completion)
        }
    }
    
    func playRandomQuestion(completion: LottieCompletionBlock? = nil) {
        // Filter question animations (question_1, question_2, question_3)
        let questionAnimations = animationNames.filter { $0.lowercased().contains("question") }
        if let randomName = questionAnimations.randomElement() {
            lastPlayedAnimationName = randomName
            loadAndPlayLottie(named: randomName, loopMode: .playOnce, completion: completion)
        } else if let randomName = animationNames.randomElement() {
            // Fallback to any animation if no question found
            lastPlayedAnimationName = randomName
            loadAndPlayLottie(named: randomName, loopMode: .playOnce, completion: completion)
        }
    }
    
    func replayLastAnimation(completion: LottieCompletionBlock? = nil) {
        // If animation exists and is not playing, try to resume/restart
        if let animationView = animationView, currentAnimationName != nil {
            if !animationView.isAnimationPlaying {
                // Check if animation is at the end (completed) or paused in the middle
                // If at the end, restart from beginning; otherwise resume
                if animationView.currentFrame >= (animationView.animation?.endFrame ?? 0) {
                    // Animation completed, restart from beginning
                    animationView.currentFrame = animationView.animation?.startFrame ?? 0
                }
                animationView.play(completion: completion)
                return
            }
        }
        
        // Otherwise, restart the last played animation
        if let lastName = lastPlayedAnimationName {
            loadAndPlayLottie(named: lastName, loopMode: .playOnce, completion: completion)
        } else if let currentName = currentAnimationName {
            loadAndPlayLottie(named: currentName, loopMode: .playOnce, completion: completion)
        }
    }

    func stop() {
        animationView?.stop()
    }

    func pause() {
        animationView?.pause()
    }
    
    func play() {
        animationView?.play()
    }
    
    var isAnimationPlaying: Bool {
        return animationView?.isAnimationPlaying ?? false
    }
    
    func setLoopMode(_ loopMode: LottieLoopMode) {
        animationView?.loopMode = loopMode
    }
    
    // MARK: - Public Getters
    var currentLottieName: String? {
        return currentAnimationName
    }
    
    // MARK: - Set Lottie Without Playing
    func setLottie(named name: String) {
        // Remove existing animation view
        animationView?.stop()
        animationView?.removeFromSuperview()
        animationView = nil

        // Load new animation efficiently
        guard let animation = LottieAnimation.named(name) else {
            print("❌ Failed to load animation: \(name)")
            return
        }

        let newAnimationView = LottieAnimationView(animation: animation)
        newAnimationView.frame = containerView.bounds
        newAnimationView.contentMode = .scaleAspectFit
        newAnimationView.loopMode = .loop
        newAnimationView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(newAnimationView)
        setupConstraints(for: newAnimationView, in: containerView)

        // Don't play the animation - just set it
        animationView = newAnimationView
        currentAnimationName = name
    }
    
    // MARK: - Cleanup and Memory Management
    /// Clean up all resources and release memory
    func cleanup() {
        // Stop and pause animation immediately
        animationView?.stop()
        animationView?.pause()
        
        // Remove all animations from the layer
        animationView?.layer.removeAllAnimations()
        
        // Remove from view hierarchy
        animationView?.removeFromSuperview()
        
        // Clear animation reference to release memory
        animationView?.animation = nil
        
        // Remove all sublayers
        animationView?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Clear the animation view completely
        animationView = nil
        
        // Clear references
        currentAnimationName = nil
        lastPlayedAnimationName = nil
        
        print("🧹 LottieManager cleanup completed - memory released")
    }
}
