import Foundation
import AVFoundation

protocol AudioPlayerManagersDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ manager: AudioPlayerManagers, successfully flag: Bool)
}

class AudioPlayerManagers: NSObject {
    static let shared = AudioPlayerManagers()
    
    private var player: AVAudioPlayer?
    private var currentTask: URLSessionDataTask?
    weak var delegate: AudioPlayerManagersDelegate?
    private var completionHandler: ((Bool) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func playAudio(from urlString: String, completion: ((Bool) -> Void)? = nil) {
        guard isConnectedToInternet() else {
            SnackbarManager.showNoInternet()
            completion?(false)
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion?(false)
            return
        }
        
        // Cancel any previous task
        currentTask?.cancel()
        stop()
        
        // Store completion handler
        completionHandler = completion
        
        // Fetch audio data in background
        currentTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Audio download error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.completionHandler?(false)
                    self.completionHandler = nil
                }
                return
            }
            
            guard let data = data else {
                print("No audio data")
                DispatchQueue.main.async {
                    self.completionHandler?(false)
                    self.completionHandler = nil
                }
                return
            }
            
            do {
                self.player = try AVAudioPlayer(data: data)
                self.player?.delegate = self
                self.player?.prepareToPlay()
                self.player?.play()
                DispatchQueue.main.async {
                    self.completionHandler?(true)
                    self.completionHandler = nil
                }
            } catch {
                print("Failed to play audio: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.completionHandler?(false)
                    self.completionHandler = nil
                }
            }
        }
        
        currentTask?.resume()
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
    
    func stop() {
        player?.stop()
        player?.delegate = nil
        player = nil
        currentTask?.cancel()
        currentTask = nil
        completionHandler = nil
    }
    
    func isPlaying() -> Bool {
        return player?.isPlaying ?? false
    }
    
    func getDuration() -> TimeInterval {
        return player?.duration ?? 0
    }
    
    func getCurrentTime() -> TimeInterval {
        return player?.currentTime ?? 0
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManagers: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.audioPlayerDidFinishPlaying(self, successfully: flag)
        }
    }
}
