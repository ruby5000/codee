import StoreKit
import UIKit

class AppReviewManager {
    
    static let shared = AppReviewManager()
    
    private let eventCountKey = "review_event_count"
    private let hasShownFirstReviewKey = "has_shown_first_review"
    private let initialTargetCount = 2 // Show on 2nd visit for new users
    private let subsequentTargetCount = 3 // Show every 3rd visit after first review
    
    /// Call this from the specified view controllers: QuestionPreviewVC, InboxPreviewVC, QuestionPreview_2VC, InboxPreview_2VC
    func maybeRequestReviewAfterThreeEvents() {
        let defaults = UserDefaults.standard
        
        var count = defaults.integer(forKey: eventCountKey)
        count += 1
        defaults.set(count, forKey: eventCountKey)
        
        // Determine target count based on whether first review has been shown
        let hasShownFirstReview = defaults.bool(forKey: hasShownFirstReviewKey)
        let targetCount = hasShownFirstReview ? subsequentTargetCount : initialTargetCount
        
        print("🔍 AppReviewManager: Event count: \(count) / Target: \(targetCount) (hasShownFirstReview: \(hasShownFirstReview))")
        
        // When event count reaches target → show prompt & reset
        if count >= targetCount {
            print("🎯 AppReviewManager: Target reached! Showing review prompt...")
            requestReview()
            defaults.set(0, forKey: eventCountKey) // Reset counter
            defaults.set(true, forKey: hasShownFirstReviewKey) // Mark that first review has been shown
            print("🔄 AppReviewManager: Counter reset to 0, hasShownFirstReview set to true")
        } else {
            print("⏳ AppReviewManager: Need \(targetCount - count) more events to show review")
        }
    }
    
    /// Schedule review request with delay. Returns a cancellable DispatchWorkItem.
    /// Cancel this work item in viewWillDisappear if user navigates back before delay completes.
    func scheduleReviewRequestAfterDelay(delay: TimeInterval = 2.0) -> DispatchWorkItem {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.maybeRequestReviewAfterThreeEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }
    
    private func requestReview() {
        print("📱 AppReviewManager: Attempting to show review prompt...")
        
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                print("✅ AppReviewManager: iOS 14+ - Using scene-based review request")
                SKStoreReviewController.requestReview(in: scene)
            } else {
                print("❌ AppReviewManager: No active scene found for iOS 14+")
            }
        } else {
            print("✅ AppReviewManager: iOS <14 - Using legacy review request")
            SKStoreReviewController.requestReview()
        }
        
        print("📱 AppReviewManager: Review request completed")
    }
    
    /// For testing purposes - reset the counter and first review flag
    func resetReviewCounter() {
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: eventCountKey)
        defaults.set(false, forKey: hasShownFirstReviewKey)
        print("🔄 AppReviewManager: Counter and first review flag manually reset")
    }
    
    /// For testing purposes - get current counter value
    func getCurrentCounter() -> Int {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: eventCountKey)
        let hasShownFirstReview = defaults.bool(forKey: hasShownFirstReviewKey)
        let targetCount = hasShownFirstReview ? subsequentTargetCount : initialTargetCount
        print("📊 AppReviewManager: Current counter value: \(count), hasShownFirstReview: \(hasShownFirstReview), target: \(targetCount)")
        return count
    }
    
    /// For testing purposes - get current state
    func getCurrentState() -> (counter: Int, hasShownFirstReview: Bool, targetCount: Int) {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: eventCountKey)
        let hasShownFirstReview = defaults.bool(forKey: hasShownFirstReviewKey)
        let targetCount = hasShownFirstReview ? subsequentTargetCount : initialTargetCount
        return (count, hasShownFirstReview, targetCount)
    }
    
    /// For testing purposes - force show review
    func forceShowReview() {
        print("🧪 AppReviewManager: Force showing review for testing...")
        requestReview()
    }
}
