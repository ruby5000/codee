import Foundation
import AVFoundation
import UIKit

class AudioHandler {

    static let shared = AudioHandler()

    private var player: AVPlayer?
    var isPlaying = false
    private var currentURLString: String?

    private init() {
        setupObservers()
    }

    // MARK: - Setup Observers for App Background
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appMovedToBackground() {
        pause()
    }

    // MARK: - Play URL
    func play(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid audio url")
            return
        }

        // Remove previous observer if exists
        if let previousItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: previousItem)
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        currentURLString = urlString

        // Observe when audio finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player?.play()
        isPlaying = true
        print("Audio started playing")
        NotificationCenter.default.post(name: NSNotification.Name("AudioDidStartPlaying"), object: nil)
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        isPlaying = false
        print("Audio finished playing")
        NotificationCenter.default.post(name: NSNotification.Name("AudioDidEnd"), object: nil)
    }

    // MARK: - Pause
    func pause() {
        player?.pause()
        isPlaying = false
        print("Audio paused")
        NotificationCenter.default.post(name: NSNotification.Name("AudioDidPause"), object: nil)
    }

    // MARK: - Stop (release player)
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        print("Audio stopped")
        NotificationCenter.default.post(name: NSNotification.Name("AudioDidPause"), object: nil)
    }

    // MARK: - Toggle Play/Pause
    func toggle(urlString: String) {
        if isPlaying {
            pause()
        } else {
            play(urlString: urlString)
        }
    }
    
    // MARK: - Resume/Replay
    func resume() {
        if let urlString = currentURLString {
            if let existingPlayer = player, !isPlaying {
                // Check if audio has ended (current time >= duration)
                if let currentItem = existingPlayer.currentItem {
                    let currentTime = existingPlayer.currentTime()
                    let duration = currentItem.duration
                    
                    // If audio has ended (within 0.1 second tolerance), restart from beginning
                    if CMTimeCompare(currentTime, duration) >= 0 || CMTimeGetSeconds(duration) - CMTimeGetSeconds(currentTime) < 0.1 {
                        // Audio has ended, restart from beginning
                        existingPlayer.seek(to: .zero) { [weak self] _ in
                            existingPlayer.play()
                            self?.isPlaying = true
                            print("Audio restarted from beginning")
                            NotificationCenter.default.post(name: NSNotification.Name("AudioDidStartPlaying"), object: nil)
                        }
                    } else {
                        // Resume from pause point
                        existingPlayer.play()
                        isPlaying = true
                        print("Audio resumed from pause")
                        NotificationCenter.default.post(name: NSNotification.Name("AudioDidStartPlaying"), object: nil)
                    }
                } else {
                    // No current item, restart from beginning
                    play(urlString: urlString)
                }
            } else {
                // Replay from beginning (player doesn't exist)
                play(urlString: urlString)
            }
        }
    }
    
    // MARK: - Check if player exists (for resume logic)
    func hasPlayer() -> Bool {
        return player != nil
    }
    
    // MARK: - Get Player (for progress tracking)
    func getPlayer() -> AVPlayer? {
        return player
    }
}
