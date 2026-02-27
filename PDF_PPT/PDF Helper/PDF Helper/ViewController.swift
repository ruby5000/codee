import UIKit
import UniformTypeIdentifiers
import PDFKit

class ViewController: UIViewController {

    private lazy var selectPDFButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select PDF to Convert", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(selectPDFTapped), for: .touchUpInside)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(selectPDFButton)
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            selectPDFButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectPDFButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func selectPDFTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func convertAndShare(pdfURL: URL) {
        selectPDFButton.isHidden = true
        activityIndicator.startAnimating()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let accessed = pdfURL.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    pdfURL.stopAccessingSecurityScopedResource()
                }
            }

            let outputFileName = (pdfURL.deletingPathExtension().lastPathComponent) + ".pptx"
            guard let savedURL = PDFToPPTConverter.convertAndSavePDFToPPT(pdfURL: pdfURL, outputFileName: outputFileName) else {
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.selectPDFButton.isHidden = false
                    let alert = UIAlertController(
                        title: "Conversion Failed",
                        message: "Could not convert PDF to PPT. The file may be corrupted or in an unsupported format.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
                return
            }

            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.selectPDFButton.isHidden = false
                self?.presentShareSheet(for: savedURL)
            }
        }
    }

    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed {
                let alert = UIAlertController(
                    title: "Done",
                    message: "PPT file saved. You can open it in PowerPoint, Keynote, or Google Slides to edit.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = selectPDFButton
            popover.sourceRect = selectPDFButton.bounds
        }
        present(activityVC, animated: true)
    }
}

extension ViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        guard let pdfURL = urls.first else { return }
        convertAndShare(pdfURL: pdfURL)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}
