//
//  ViewController.swift
//  PDF Helper
//
//  Created by Chiku on 20/02/26.
//

import UIKit
import UniformTypeIdentifiers
import WebKit
import CoreText

class ViewController: UIViewController {

    private var pickedDocumentURL: URL?
    private var pickedDocumentData: Data?
    private var hasPresentedPicker = false

    /// Hidden WKWebView used to render Word documents for PDF conversion.
    private var webView: WKWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasPresentedPicker else { return }
        hasPresentedPicker = true
        openDocumentPicker()
    }

    // MARK: - Document Picker

    private func openDocumentPicker() {
        let types: [UTType] = [
            UTType(filenameExtension: "doc") ?? .plainText,
            UTType(filenameExtension: "docx") ?? .plainText,
            UTType(filenameExtension: "ppt") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data,
            .plainText,
            .rtf
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    // MARK: - Debug: Print File Info

    private func printFileNameAndData() {
        guard let url = pickedDocumentURL else { return }
        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        print("──────────────────────────────────")
        print("📄 Picked file name: \(name)")
        print("📄 File extension: .\(ext)")
        print("📄 File URL: \(url)")

        if let data = pickedDocumentData {
            print("📄 File data size: \(data.count) bytes")
            let header = data.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " ")
            print("📄 File header (hex): \(header)")
        } else {
            print("⚠️ File data: could not read")
        }
        print("──────────────────────────────────")
    }

    // MARK: - Conversion Entry Point

    private func convertToPDFAndSave() {
        guard let url = pickedDocumentURL, let data = pickedDocumentData else {
            print("❌ No document data to convert")
            return
        }

        let ext = url.pathExtension.lowercased()
        print("🔄 Starting conversion for .\(ext) file...")

        switch ext {
        case "doc", "docx", "ppt", "pptx":
            convertToWebViewPDF(url: url, data: data)
        default:
            convertUsingAttributedString(url: url, data: data)
        }
    }

    // MARK: - Word / PPT → PDF via WKWebView

    private func convertToWebViewPDF(url: URL, data: Data) {
        let ext = url.pathExtension.lowercased()
        print("🌐 Using WKWebView to render .\(ext) document...")

        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(url.lastPathComponent)
        do {
            try data.write(to: tempFile)
            print("✅ Temp file written at: \(tempFile.path)")
        } catch {
            print("❌ Failed to write temp file: \(error)")
            saveFallbackPDF(url: url, data: data, reason: "Failed to write temp file: \(error.localizedDescription)")
            return
        }

        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 792))
        wv.navigationDelegate = self
        wv.isHidden = true
        view.addSubview(wv)
        self.webView = wv

        print("🌐 Loading document into WKWebView...")
        wv.loadFileURL(tempFile, allowingReadAccessTo: tempDir)
    }

    private func generatePDFFromWebView() {
        guard let wv = self.webView else {
            print("❌ WebView is nil when trying to generate PDF")
            return
        }

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let printableRect = CGRect(x: margin, y: margin,
                                   width: pageWidth - 2 * margin,
                                   height: pageHeight - 2 * margin)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let printFormatter = wv.viewPrintFormatter()

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pageCount = renderer.numberOfPages
        print("🖨️ UIPrintPageRenderer reports \(pageCount) page(s)")

        guard pageCount > 0 else {
            print("❌ Renderer says 0 pages")
            wv.removeFromSuperview()
            self.webView = nil
            if let url = pickedDocumentURL, let data = pickedDocumentData {
                saveFallbackPDF(url: url, data: data, reason: "Renderer produced 0 pages")
            }
            return
        }

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        for i in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        print("✅ PDF rendered: \(pdfData.length) bytes, \(pageCount) page(s)")
        wv.removeFromSuperview()
        self.webView = nil
        savePDFToDocuments(pdfData: pdfData as Data)
    }

    // MARK: - RTF / TXT → PDF via AttributedString + CoreText

    private func convertUsingAttributedString(url: URL, data: Data) {
        let ext = url.pathExtension.lowercased()
        print("📝 Using NSAttributedString path for .\(ext)...")

        var attr: NSAttributedString?

        switch ext {
        case "rtf", "rtfd":
            do {
                attr = try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                print("✅ RTF loaded: \(attr?.length ?? 0) characters")
            } catch {
                print("❌ Failed to load RTF: \(error)")
            }
        case "txt":
            if let str = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) {
                attr = NSAttributedString(string: str, attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ])
                print("✅ TXT loaded: \(attr?.length ?? 0) characters")
            } else {
                print("❌ Could not decode text file with UTF-8 or UTF-16")
            }
        default:
            if let str = String(data: data, encoding: .utf8) {
                attr = NSAttributedString(string: str, attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ])
                print("✅ Loaded as plain text: \(attr?.length ?? 0) characters")
            } else {
                print("❌ Could not decode file as text")
            }
        }

        if let attr = attr, attr.length > 0 {
            if let pdfData = renderAttributedStringToPDF(attr) {
                print("✅ Multi-page PDF rendered: \(pdfData.count) bytes")
                savePDFToDocuments(pdfData: pdfData)
            } else {
                print("❌ renderAttributedStringToPDF returned nil")
                saveFallbackPDF(url: url, data: data, reason: "PDF rendering failed")
            }
        } else {
            print("⚠️ No attributed string produced, using fallback PDF")
            saveFallbackPDF(url: url, data: data, reason: "Could not extract text from .\(ext) file")
        }
    }

    // MARK: - Multi-Page PDF Rendering with CoreText

    private func renderAttributedStringToPDF(_ attr: NSAttributedString) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 72
        let textWidth = pageWidth - 2 * margin

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: pageWidth, height: pageHeight)))
        return renderer.pdfData { ctx in
            let fullLength = attr.length
            guard fullLength > 0 else {
                ctx.beginPage()
                return
            }
            let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
            var charIndex = 0
            var pageNum = 0

            while charIndex < fullLength {
                ctx.beginPage()
                pageNum += 1
                let frameRect = CGRect(x: margin, y: margin, width: textWidth, height: pageHeight - 2 * margin)
                let path = CGPath(rect: frameRect, transform: nil)
                let frameRange = CFRange(location: charIndex, length: fullLength - charIndex)
                let frame = CTFramesetterCreateFrame(framesetter, frameRange, path, nil)
                let visibleRange = CTFrameGetVisibleStringRange(frame)
                if visibleRange.length == 0 { break }
                let cgContext = ctx.cgContext
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: pageHeight)
                cgContext.scaleBy(x: 1, y: -1)
                CTFrameDraw(frame, cgContext)
                cgContext.restoreGState()
                charIndex += visibleRange.length
            }
            print("📄 Rendered \(pageNum) page(s)")
        }
    }

    // MARK: - Save PDF

    private func savePDFToDocuments(pdfData: Data) {
        guard let url = pickedDocumentURL else { return }
        let name = url.deletingPathExtension().lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsURL.appendingPathComponent("\(name).pdf")

        do {
            try pdfData.write(to: pdfURL)
            print("──────────────────────────────────")
            print("✅ PDF saved successfully!")
            print("📁 Path: \(pdfURL.path)")
            print("📦 Size: \(pdfData.count) bytes")
            print("──────────────────────────────────")
        } catch {
            print("❌ Failed to save PDF: \(error)")
        }
    }

    // MARK: - Fallback PDF

    private func saveFallbackPDF(url: URL, data: Data, reason: String) {
        print("⚠️ Creating fallback PDF. Reason: \(reason)")
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 72
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: pageWidth, height: pageHeight)))
        let pdfData = renderer.pdfData { ctx in
            ctx.beginPage()
            let text = """
            Converted from: \(url.lastPathComponent)
            File size: \(data.count) bytes

            Error: \(reason)
            """
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            (text as NSString).draw(in: CGRect(x: margin, y: margin, width: pageWidth - 2 * margin, height: 200), withAttributes: attrs)
        }
        savePDFToDocuments(pdfData: pdfData)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        guard let url = urls.first else { return }

        pickedDocumentURL = url

        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                pickedDocumentData = try Data(contentsOf: url)
            } catch {
                print("❌ Could not read file data: \(error)")
            }
        } else {
            do {
                pickedDocumentData = try Data(contentsOf: url)
            } catch {
                print("❌ Could not read file data: \(error)")
            }
        }

        printFileNameAndData()

        print("⏳ Will convert to PDF in 6 seconds...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.convertToPDFAndSave()
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        print("Document picker was cancelled")
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ WKWebView finished loading document")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.generatePDFFromWebView()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WKWebView navigation failed: \(error)")
        webView.removeFromSuperview()
        self.webView = nil
        if let url = pickedDocumentURL, let data = pickedDocumentData {
            saveFallbackPDF(url: url, data: data, reason: "WebView failed to load: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ WKWebView provisional navigation failed: \(error)")
        webView.removeFromSuperview()
        self.webView = nil
        if let url = pickedDocumentURL, let data = pickedDocumentData {
            saveFallbackPDF(url: url, data: data, reason: "WebView failed to load: \(error.localizedDescription)")
        }
    }
}
