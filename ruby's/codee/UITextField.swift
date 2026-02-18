import UIKit

extension UITextField {
    
    /// Adds a localized Done button on the keyboard
    func addDoneButton() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Localized title
        let doneTitle = NSLocalizedString("done_button_title", comment: "Done button on keyboard")
        
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let doneButton = UIBarButtonItem(title: doneTitle,
                                         style: .done,
                                         target: self,
                                         action: #selector(doneButtonTapped))
        
        toolbar.items = [flexible, doneButton]
        self.inputAccessoryView = toolbar
    }
    
    @objc private func doneButtonTapped() {
        self.resignFirstResponder()
    }
}
