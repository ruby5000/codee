import UIKit

final class AlertHelper {

    static func showAlert(
        title: String,
        message: String,
        buttonTitle: String = "OK",
        completion: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            guard let topVC = UIApplication.shared.topMostViewController() else {
                debugPrint("❌ Unable to find top view controller")
                return
            }

            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )

            let action = UIAlertAction(title: buttonTitle, style: .default) { _ in
                completion?()
            }

            alert.addAction(action)
            topVC.present(alert, animated: true)
        }
    }
}
