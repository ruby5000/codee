# Image Manager — How to Use

This guide describes the **Image Manager** and how to use it for async image loading, memory and disk caching, placeholders, resize, and compression in iOS apps. It is built on **SDWebImage**.

---

## 1. Overview

**ImageManager** provides:

- **Async image download** — Load from URL in the background; UI stays responsive.
- **Memory + disk caching** — SDWebImage caches images in memory and on disk by default; ImageManager exposes prefetch, clear, and cache checks.
- **Placeholder handling** — Show a placeholder image while loading.
- **Resize / compression** — Load images at a max size (e.g. thumbnails) to save memory; compress to JPEG when needed.

All APIs are static on `ImageManager`; you can also use the `UIImageView` extension methods (`im_setImage`, `im_setImage(with:placeholder:maxSize:...)`, `im_cancelLoad`).

**Dependency:** [SDWebImage](https://github.com/SDWebImage/SDWebImage). Add it via Swift Package Manager or CocoaPods (see **Setup** below).

---

## 2. Quick reference

| Need | Use |
|------|-----|
| Load URL into image view | `ImageManager.load(into:url:placeholder:completed:)` or `imageView.im_setImage(with:placeholder:completed:)` |
| Load with max size (e.g. list cell) | `ImageManager.load(into:url:placeholder:maxSize:completed:)` or `imageView.im_setImage(with:placeholder:maxSize:completed:)` |
| Load image without image view (async/await) | `let image = try await ImageManager.loadImage(url: url)` |
| Load with resize (async/await) | `try await ImageManager.loadImage(url:url, maxSize:CGSize(width:200, height:200))` |
| Cancel current load on image view | `ImageManager.cancelLoad(on: imageView)` or `imageView.im_cancelLoad()` |
| Prefetch URLs | `ImageManager.prefetch(urls: [url1, url2], completion: nil)` |
| Clear memory cache | `ImageManager.clearMemoryCache(completion: nil)` |
| Clear disk cache | `ImageManager.clearDiskCache(completion: nil)` |
| Remove cache for one URL | `ImageManager.removeCachedImage(for: url, completion: nil)` |
| Check if in memory cache | `ImageManager.isCachedInMemory(url: url)` |
| Check if on disk (async) | `ImageManager.isCachedOnDisk(url: url) { exists in ... }` |
| Compress to JPEG | `ImageManager.compressToJPEG(image, quality: 0.8)` |
| Resize + compress (e.g. thumbnail) | `ImageManager.compressImage(image, maxDimension: 200, jpegQuality: 0.8)` |

---

## 3. Setup

### 3.1 Add SDWebImage

**Swift Package Manager (recommended)**

1. In Xcode: **File → Add Package Dependencies…**
2. Enter: `https://github.com/SDWebImage/SDWebImage`
3. Add the **SDWebImage** library to your app target.

**CocoaPods**

```ruby
pod 'SDWebImage'
```

Then run `pod install` and open the `.xcworkspace`.

### 3.2 Add ImageManager to your project

Add **ImageManager.swift** (and the **Image** folder) to your Xcode project and ensure the file is in your app target. No extra setup is required; ImageManager uses the shared `SDWebImageManager` and `SDImageCache`.

---

## 4. Loading into UIImageView

### 4.1 Basic load with placeholder

```swift
import UIKit

// In a table view cell or any view controller
let imageURL = URL(string: "https://example.com/photo.jpg")!
let placeholder = UIImage(named: "placeholder")

ImageManager.load(into: imageView, url: imageURL, placeholder: placeholder) { image, error, cacheType, url in
    if error != nil {
        // Optional: show error state
        return
    }
    // image is set on the imageView automatically; use cacheType if needed (.memory, .disk, .none)
}
```

Or with the extension:

```swift
imageView.im_setImage(with: imageURL, placeholder: placeholder) { image, error, cacheType, url in
    // ...
}
```

### 4.2 Load with max size (thumbnails / list cells)

Reduces memory by decoding the image at a smaller size. Use for list or grid cells.

```swift
let cellSize = CGSize(width: 80, height: 80)
ImageManager.load(
    into: cell.imageView,
    url: imageURL,
    placeholder: UIImage(named: "placeholder"),
    maxSize: cellSize,
    scaleMode: .aspectFill
) { image, error, _, _ in
    // ...
}
```

Or:

```swift
cell.imageView.im_setImage(with: imageURL, placeholder: nil, maxSize: CGSize(width: 80, height: 80))
```

### 4.3 Cancel load (e.g. cell reuse)

In `prepareForReuse` or when the image view is about to show a different URL, cancel the previous load:

```swift
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.im_cancelLoad()
}
```

---

## 5. Programmatic load (no image view)

When you need the image for something other than an image view (e.g. share sheet, export, upload):

```swift
let image = try await ImageManager.loadImage(url: url)
// use image
```

With a max size (resize):

```swift
let image = try await ImageManager.loadImage(url: url, maxSize: CGSize(width: 400, height: 400))
```

Handle errors:

```swift
do {
    let image = try await ImageManager.loadImage(url: url)
    // use image
} catch {
    // handle error (invalid URL, network, no image)
}
```

---

## 6. Prefetching

Prefetch URLs so they are in memory/disk cache before the user scrolls to them. Call from a list screen (e.g. in `viewDidLoad` or when you receive a list of URLs):

```swift
let urls = items.compactMap { URL(string: $0.imageURL) }
ImageManager.prefetch(urls: urls) {
    // optional: all done
}
```

---

## 7. Cache control

- **Clear memory cache** (e.g. on memory warning):  
  `ImageManager.clearMemoryCache(completion: nil)`

- **Clear disk cache** (e.g. in Settings):  
  `ImageManager.clearDiskCache { /* done */ }`

- **Remove one URL from cache**:  
  `ImageManager.removeCachedImage(for: url, completion: nil)`

- **Check if URL is in memory cache** (synchronous):  
  `let inMemory = ImageManager.isCachedInMemory(url: url)`

- **Check if URL is on disk** (asynchronous):  
  `ImageManager.isCachedOnDisk(url: url) { exists in ... }`

---

## 8. Resize and compression

### 8.1 Resize at load time

Use `maxSize` when loading so the decoded image is smaller (saves memory):

```swift
ImageManager.load(into: imageView, url: url, placeholder: nil, maxSize: CGSize(width: 300, height: 300), scaleMode: .aspectFill)
```

`scaleMode` options (from SDWebImage): `.fill`, `.aspectFit`, `.aspectFill`.

### 8.2 Compress after load

When you need JPEG data (e.g. upload or save):

```swift
guard let image = imageView.image else { return }
if let data = ImageManager.compressToJPEG(image, quality: 0.8) {
    // use data
}
```

### 8.3 Resize and compress (thumbnail)

When you have a large image and need a smaller, compressed version:

```swift
if let thumbnail = ImageManager.compressImage(largeImage, maxDimension: 200, jpegQuality: 0.8) {
    // use thumbnail (smaller in memory and on disk if you save it)
}
```

---

## 9. Advanced: options and context

For more control, use the full `load(into:url:placeholder:options:context:progress:completed:)` API:

- **options** — e.g. `SDWebImageOptions.retryFailed`, `.refreshCached`.
- **context** — e.g. custom transformer:  
  `[.imageTransformer: ImageManager.resizeTransformer(size: size, scaleMode: .aspectFill)]`
- **progress** — `{ received, expected in ... }` for progress UI.

Example with progress:

```swift
ImageManager.load(
    into: imageView,
    url: url,
    placeholder: placeholder,
    progress: { received, expected in
        let progress = expected > 0 ? Float(received) / Float(expected) : 0
        progressView.progress = progress
    },
    completed: { image, error, _, _ in
        progressView.isHidden = true
    }
)
```

---

## 10. Summary

- **Load into image view:** `ImageManager.load(into:url:placeholder:...)` or `imageView.im_setImage(with:placeholder:...)`; use `maxSize` for thumbnails.
- **Load without image view:** `try await ImageManager.loadImage(url:)` or `loadImage(url:maxSize:)`.
- **Placeholder:** Pass a `UIImage?` as `placeholder`.
- **Memory + disk cache:** Handled by SDWebImage; use `prefetch`, `clearMemoryCache`, `clearDiskCache`, `removeCachedImage`, `isCachedInMemory`, `isCachedOnDisk` as needed.
- **Resize:** Use `maxSize` in load APIs or `resizeTransformer(size:scaleMode:)` in context; for one-off resize+compress use `compressImage(_:maxDimension:jpegQuality:)`.
- **Cancel:** `ImageManager.cancelLoad(on: imageView)` or `imageView.im_cancelLoad()`.

For more details, see the inline documentation in **ImageManager.swift** and the [SDWebImage documentation](https://github.com/SDWebImage/SDWebImage).
