import Foundation

final class CooldownManager {

    private static let startTimeKey = "COOLDOWN_START_TIME"
    private static let durationKey  = "COOLDOWN_DURATION"

    /// Start cooldown with custom duration (in seconds)
    static func start(duration seconds: Int) {
        let startTime = Date().timeIntervalSince1970

        UserDefaults.standard.set(startTime, forKey: startTimeKey)
        UserDefaults.standard.set(seconds, forKey: durationKey)

        print("⏱ [CooldownManager] Timer ACTIVATED")
        print("➡️ Duration:", seconds, "seconds")
        print("➡️ Start Time:", startTime)
    }

    /// Remaining seconds (0 = expired)
    static func remainingSeconds() -> Int {
        guard
            let startTime = UserDefaults.standard.object(forKey: startTimeKey) as? TimeInterval,
            let duration = UserDefaults.standard.object(forKey: durationKey) as? Int
        else {
            print("⚠️ [CooldownManager] No active timer found")
            return 0
        }

        let elapsed = Int(Date().timeIntervalSince1970 - startTime)
        let remaining = max(duration - elapsed, 0)

        if remaining > 0 {
            print("⏳ [CooldownManager] Timer ACTIVE | Remaining:", remaining, "sec")
        } else {
            print("❌ [CooldownManager] Timer EXPIRED")
        }

        return remaining
    }

    /// Elapsed seconds since start
    static func elapsedSeconds() -> Int {
        guard
            let startTime = UserDefaults.standard.object(forKey: startTimeKey) as? TimeInterval
        else {
            return 0
        }

        let elapsed = Int(Date().timeIntervalSince1970 - startTime)
        print("⏳ [CooldownManager] Elapsed:", elapsed, "sec")
        return elapsed
    }

    /// Check if cooldown is still active
    static func isActive() -> Bool {
        let active = remainingSeconds() > 0
        print("🔄 [CooldownManager] isActive =", active)
        return active
    }

    /// Clear cooldown manually
    static func reset() {
        UserDefaults.standard.removeObject(forKey: startTimeKey)
        UserDefaults.standard.removeObject(forKey: durationKey)

        print("🧹 [CooldownManager] Timer RESET")
    }
}
