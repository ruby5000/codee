import UIKit

class ShimmerCell: UICollectionViewCell {
    static let identifier = "ShimmerCell"

    private let containerView = UIView()
    private let fullBox = ShimmerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        fullBox.startAnimating() // Restart animation
    }

    private func setupViews() {
        containerView.isUserInteractionEnabled = false
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)

        fullBox.translatesAutoresizingMaskIntoConstraints = false
        fullBox.layer.cornerRadius = 8
        fullBox.clipsToBounds = true
        containerView.addSubview(fullBox)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            fullBox.topAnchor.constraint(equalTo: containerView.topAnchor),
            fullBox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            fullBox.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            fullBox.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}
