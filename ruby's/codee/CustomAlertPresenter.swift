import UIKit

final class CustomAlertPresenter {

    static func show(
        message: String,
        duration: TimeInterval = 1.5,
        dimAlpha: CGFloat = 0.25   // 🔹 control dim strength
    ) {

        DispatchQueue.main.async {

            guard let window = UIApplication.shared
                .connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first else {
                return
            }

            // 🔳 Dim background view
            let dimView = UIView()
            dimView.backgroundColor = UIColor.black
            dimView.alpha = 0
            dimView.isUserInteractionEnabled = false // 🔑 touches pass through

            window.addSubview(dimView)
            dimView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                dimView.topAnchor.constraint(equalTo: window.topAnchor),
                dimView.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                dimView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                dimView.trailingAnchor.constraint(equalTo: window.trailingAnchor)
            ])

            // 🔔 Alert view
            let alertView = ToastAlertView(message: message)
            alertView.alpha = 0
            alertView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

            window.addSubview(alertView)
            alertView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                alertView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                alertView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
                alertView.widthAnchor.constraint(
                    lessThanOrEqualTo: window.widthAnchor,
                    multiplier: 0.75
                )
            ])

            // 🎬 Show animation
            UIView.animate(withDuration: 0.25) {
                dimView.alpha = dimAlpha
                alertView.alpha = 1
                alertView.transform = .identity
            }

            // ⏱ Auto dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.25, animations: {
                    dimView.alpha = 0
                    alertView.alpha = 0
                    alertView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }) { _ in
                    dimView.removeFromSuperview()
                    alertView.removeFromSuperview()
                }
            }
        }
    }
}
