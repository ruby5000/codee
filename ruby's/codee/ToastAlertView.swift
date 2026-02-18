import UIKit

final class ToastAlertView: UIView {

    private let messageLabel = UILabel()

    init(message: String) {
        super.init(frame: .zero)
        setupUI(message: message)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(message: String) {

        backgroundColor = UIColor(named: "alertBG")
        layer.cornerRadius = 14
        layer.masksToBounds = true

        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
}

