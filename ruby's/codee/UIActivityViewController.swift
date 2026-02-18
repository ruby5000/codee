import Foundation
import UIKit

extension UIActivityViewController {
    func configureForIPad(sourceView: UIView) {
        if let popover = popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
    }
}
