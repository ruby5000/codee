# Download Manager — How to Use

**Generic file download** with progress and cancellation. Uses URLSession (no Alamofire).

---

## 1. Overview

**DownloadManager** provides:

- **Download** — Any file type to Documents/Downloads
- **Progress** — Callback (basic; use VideoDownloadManager for full progress with Alamofire)
- **Cancel** — Cancel single or all
- **Task** — DownloadTask for tracking

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Download | `DownloadManager.download(url:fileName:progress:completion:)` |
| Download from string | `DownloadManager.download(urlString:...)` |
| Cancel task | `DownloadManager.cancel(task)` |
| Cancel all | `DownloadManager.cancelAll()` |
| Download dir | `DownloadManager.downloadDirectory` |

---

## 3. Setup

Add **DownloadManager.swift** to your target. No dependencies.

---

## 4. Usage

```swift
let task = DownloadManager.download(
    urlString: "https://example.com/file.pdf",
    fileName: "document.pdf",
    progress: { p in progressView.progress = Float(p) },
    completion: { result in
        switch result {
        case .success(let url): print("Saved to \(url)")
        case .failure(let error): ErrorHandler.handle(error)
        }
    }
)

// Cancel
DownloadManager.cancel(task!)
```

---

## 5. VideoDownloadManager

For video-specific downloads with Alamofire and full progress, use existing **VideoDownloadManager**.

---

## 6. Summary

- **Download:** download(url:...), download(urlString:...)
- **Cancel:** cancel, cancelAll
- **Config:** downloadDirectory

For more detail, see **DownloadManager.swift**.
