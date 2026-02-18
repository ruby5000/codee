import Foundation
import FirebaseAnalytics

final class FirebaseEventManager {
    
    static let shared = FirebaseEventManager()

    private init() {}

    // MARK: - Purchase Button Clicked
    func logPurchaseButtonClick() {
        Analytics.logEvent("ios_purchase_clicked", parameters: nil)
        print("🔥 Firebase Event: ios_purchase_clicked")
    }

    // MARK: - Purchase Success
    func logPurchaseSuccess(productId: String) {
        let params: [String: Any] = [
            "product_id": productId,
            "status": "success"
        ]

        Analytics.logEvent("ios_purchase_success", parameters: params)
        print("🔥 Event: ios_purchase_succss params: \(params)")
    }
}
