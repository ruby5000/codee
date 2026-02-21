# Media Manager — How to Use

Centralized **media handling** for video, audio, thumbnails, and saving to Photos. Use **ImageManager** for image loading and caching.

---

## 1. Overview

**MediaManager** provides:

- **Video thumbnails** — Generate thumbnail images from video URLs.
- **Video duration** — Get duration in seconds or formatted string.
- **Save to Photos** — Save video or image to the photo library.
- **File size** — Get file size in bytes or formatted string.
- **Media type detection** — Detect video/audio/image from URL.

**ImageManager** (in `Manager/Image/`) handles:
- Async image loading into `UIImageView`
- Memory + disk caching (SDWebImage)
- Prefetch, resize, compression

Use **MediaManager** for video/audio; use **ImageManager** for images.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Video thumbnail | `try await MediaManager.thumbnail(for: videoURL)` |
| Video duration (seconds) | `try await MediaManager.duration(of: url)` |
| Formatted duration | `try await MediaManager.formattedDuration(of: url)` |
| Save video to Photos | `try await MediaManager.saveVideo(toPhotos: url)` |
| Save image to Photos | `try await MediaManager.saveImage(toPhotos: image)` |
| File size (bytes) | `MediaManager.fileSize(of: url)` |
| Formatted file size | `MediaManager.formattedFileSize(of: url)` |
| Detect media type | `MediaManager.mediaType(for: url)` |

---

## 3. Setup

### 3.1 Add to Xcode

Add **MediaManager.swift** (and **Media** folder) to your app target. Uses **AVFoundation** and **Photos** (no extra dependencies).

### 3.2 Info.plist

For saving to Photos, add:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save videos and images to your photo library.</string>
```

For reading videos (if needed), add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to select videos from your library.</string>
```

---

## 4. Video Thumbnails

### 4.1 From URL

```swift
let videoURL = URL(string: "https://example.com/video.mp4")!
let thumbnail = try await MediaManager.thumbnail(for: videoURL)
imageView.image = thumbnail
```

### 4.2 At Specific Time

```swift
let time = CMTime(seconds: 5, preferredTimescale: 600)
let thumbnail = try await MediaManager.thumbnail(for: videoURL, at: time)
```

### 4.3 From Local Path

```swift
let thumb = try await MediaManager.thumbnail(for: "videos/recorded.mp4", in: true)
```

---

## 5. Video Duration

```swift
let seconds = try await MediaManager.duration(of: videoURL)
// 125.5

let formatted = try await MediaManager.formattedDuration(of: videoURL)
// "2:05"
```

---

## 6. Save to Photos

### 6.1 Save Video

```swift
do {
    try await MediaManager.saveVideo(toPhotos: localVideoURL)
    // Show success
} catch {
    // Handle permission denied or failure
}
```

### 6.2 Save Image

```swift
try await MediaManager.saveImage(toPhotos: image)
```

**Note:** Request Photos permission with `PermissionManager.request(.photos)` before saving.

---

## 7. File Size

```swift
if let bytes = MediaManager.fileSize(of: url) {
    print("\(bytes) bytes")
}

if let formatted = MediaManager.formattedFileSize(of: url) {
    print(formatted)  // "2.5 MB"
}
```

---

## 8. Media Type Detection

```swift
switch MediaManager.mediaType(for: url) {
case .image:
    // Use ImageManager
case .video:
    // Use AVPlayer or thumbnail
case .audio:
    // Use AVAudioPlayer
}
```

---

## 9. ImageManager vs MediaManager

| Task | Manager |
|------|---------|
| Load image from URL into UIImageView | **ImageManager** |
| Cache images (memory + disk) | **ImageManager** |
| Prefetch image URLs | **ImageManager** |
| Compress/resize image | **ImageManager** |
| Video thumbnail | **MediaManager** |
| Video duration | **MediaManager** |
| Save video/image to Photos | **MediaManager** |
| File size, media type | **MediaManager** |

See **IMAGE_MANAGER_README.md** for ImageManager usage.

---

## 10. Summary

- **Thumbnails:** `thumbnail(for:at:)` for video URLs.
- **Duration:** `duration(of:)`, `formattedDuration(of:)`.
- **Save:** `saveVideo(toPhotos:)`, `saveImage(toPhotos:)`.
- **File size:** `fileSize(of:)`, `formattedFileSize(of:)`.
- **Type:** `mediaType(for:)` for video/audio/image.

For more detail, see **MediaManager.swift**.
