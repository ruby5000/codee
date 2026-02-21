# Permission Manager — How to Use

Centralizes **iOS permission** checks and requests. Use from a service or coordinator so **permission logic stays out of view controllers**.

---

## 1. Overview

**PermissionManager** provides:

- **Unified API** — One `PermissionKind` enum and one `PermissionStatus` for all types.
- **Async/await** — `status(for:)` and `request(_:)` return `PermissionStatus`; safe to call from any thread (status checks avoid main-thread I/O on iOS 18+).
- **All common iOS permissions** — Camera, microphone, photos, location, notifications, Bluetooth, contacts, calendar, reminders, speech recognition, Face ID, motion, media library, app tracking (ATT).

**Permission kinds:**  
`camera`, `microphone`, `photos`, `photosAddOnly`, `locationWhenInUse`, `locationAlways`, `notifications`, `bluetooth`, `contacts`, `calendar`, `reminders`, `speechRecognition`, `faceID`, `motion`, `mediaLibrary`, `tracking`.

**Status values:**  
`notDetermined`, `authorized`, `denied`, `restricted`, `limited` (photos only). Use `status.isGranted` when you only need “can use.”

---

## 2. Quick reference

| Need | Use |
|------|-----|
| Check status | `let status = await PermissionManager.status(for: .camera)` |
| Request (shows alert if needed) | `let status = await PermissionManager.request(.camera)` |
| Request only if not yet asked | `let status = await PermissionManager.requestIfNeeded(.camera)` |
| Check if granted | `if status.isGranted { ... }` |

---

## 3. Required Info.plist keys

Add a **usage description** for every permission you request. Otherwise the app can crash or the prompt may not show correctly.

| Permission | Info.plist key | Example value |
|------------|----------------|---------------|
| Camera | `NSCameraUsageDescription` | "We need camera access to take photos." |
| Microphone | `NSMicrophoneUsageDescription` | "We need microphone access for voice messages." |
| Photos (read/write) | `NSPhotoLibraryUsageDescription` | "We need photo library access to choose and save photos." |
| Photos (add only) | `NSPhotoLibraryAddUsageDescription` | "We need permission to save photos to your library." |
| Location when in use | `NSLocationWhenInUseUsageDescription` | "We use your location to show nearby places." |
| Location always | `NSLocationAlwaysAndWhenInUseUsageDescription` | "We use your location in the background for alerts." |
| Contacts | `NSContactsUsageDescription` | "We need contacts to help you invite friends." |
| Calendar | `NSCalendarsUsageDescription` | "We need calendar access to add events." |
| Reminders | `NSRemindersUsageDescription` | "We need reminders access to create tasks." |
| Speech recognition | `NSSpeechRecognitionUsageDescription` | "We use speech recognition for voice search." |
| Motion & fitness | `NSMotionUsageDescription` | "We use motion data for activity features." |
| Media library (Apple Music) | `NSAppleMusicUsageDescription` | "We need access to your music library." |
| Bluetooth | `NSBluetoothAlwaysUsageDescription` (optional; used when Core Bluetooth prompt appears) | "We use Bluetooth for device sync." |
| Face ID | (no key; use `NSFaceIDUsageDescription` if you show a custom reason) | "We use Face ID to sign in." |
| Tracking (ATT) | (no key; system shows its own prompt) | — |

---

## 4. Basic usage

### 4.1 Check status

Call from a coordinator, service, or view model — not necessarily from the main thread.

```swift
let status = await PermissionManager.status(for: .camera)
switch status {
case .notDetermined:
    // Never asked yet
case .authorized, .limited:
    // Can use
case .denied:
    // User said no
case .restricted:
    // Parental controls / MDM
}
```

Simple check:

```swift
if await PermissionManager.status(for: .microphone).isGranted {
    startRecording()
}
```

### 4.2 Request permission

Shows the system alert only when status is `.notDetermined`. Returns the status after the user responds (or immediately if already determined).

```swift
let status = await PermissionManager.request(.camera)
if status.isGranted {
    presentCamera()
} else {
    showSettingsAlert()
}
```

### 4.3 Request only if needed

Use when you want to prompt at most once (e.g. on first use of a feature):

```swift
let status = await PermissionManager.requestIfNeeded(.photos)
if !status.isGranted {
    showPhotoPermissionExplanation()
}
```

---

## 5. Use from a coordinator or service

Keep view controllers thin: call PermissionManager from a **coordinator** or **permission service**, then drive UI from the result.

**Example: coordinator**

```swift
// In a flow coordinator
func openCamera() {
    Task {
        let status = await PermissionManager.requestIfNeeded(.camera)
        await MainActor.run {
            if status.isGranted {
                self.presentCameraScreen()
            } else {
                self.showPermissionDeniedAlert()
            }
        }
    }
}
```

**Example: dedicated service**

```swift
final class PermissionService {
    func ensureCameraAccess() async -> Bool {
        let status = await PermissionManager.requestIfNeeded(.camera)
        return status.isGranted
    }

    func ensurePhotoLibraryAccess() async -> Bool {
        let status = await PermissionManager.requestIfNeeded(.photos)
        return status.isGranted
    }
}
```

Your view controller only calls something like `permissionService.ensureCameraAccess()` and reacts to the Bool; it does not import AVFoundation or know about `PermissionKind`.

---

## 6. Permission-specific notes

### Camera & microphone

- Use `.camera` and `.microphone` separately; request only the one you need.
- Both use AVFoundation; add the corresponding Info.plist keys.

### Photos

- **`.photos`** — Read/write (iOS 14+ uses “Full Access” / “Limited”).
- **`.photosAddOnly`** — Add new photos only (iOS 14+); no read. Use when you only need to save.

### Location

- **`.locationWhenInUse`** — Foreground only.
- **`.locationAlways`** — Includes background; user may get “When In Use” first, then “Always” later. Add both keys if you need “Always.”
- Status is read on the current thread; request is async and uses the system dialog.

### Notifications

- **`.notifications`** — Push + badge + sound. Request when you need remote notifications or local alerts.
- First time you request, the system shows the alert; subsequent calls return current status.

### Bluetooth

- **`.bluetooth`** — Core Bluetooth. System prompt appears when the app first uses Bluetooth (e.g. creating `CBCentralManager`). `request(.bluetooth)` can trigger that and wait for the result.
- No Info.plist key; add `NSBluetoothAlwaysUsageDescription` (or `NSBluetoothPeripheralUsageDescription` on older iOS) if you use Bluetooth and want a custom message in the prompt.

### Contacts, calendar, reminders

- Each has its own kind and Info.plist key. Request when the user taps “Import contacts,” “Add to calendar,” etc.

### Speech recognition

- **`.speechRecognition`** — Requires `NSSpeechRecognitionUsageDescription`. Also needs microphone if you record audio.

### Face ID

- **`.faceID`** — Biometrics. `status` reflects whether Face ID is available and enrolled. `request` runs the Face ID prompt; use a clear “localized reason” in your own UI before calling.

### Motion

- **`.motion`** — Motion & fitness. Add `NSMotionUsageDescription`. Request triggers the system prompt when you use motion APIs.

### Media library

- **`.mediaLibrary`** — Apple Music / media library. Add `NSAppleMusicUsageDescription`.

### Tracking (ATT)

- **`.tracking`** — App Tracking Transparency (iOS 14+). Request only when you need to track across apps/sites; show your own explanation screen before calling `request(.tracking)`.

---

## 7. Opening Settings

When status is `.denied`, you can send the user to your app’s page in Settings:

```swift
if await PermissionManager.status(for: .camera) == .denied {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        await UIApplication.shared.open(url)
    }
}
```

---

## 8. Summary

- **Centralize** — Use `PermissionManager` in a coordinator or service; view controllers only react to “granted” or “not granted.”
- **Info.plist** — Add the usage description key for every permission you request.
- **Check** — `await PermissionManager.status(for: .camera)`.
- **Request** — `await PermissionManager.request(.camera)` or `requestIfNeeded(.camera)`.
- **Result** — `PermissionStatus` with `notDetermined`, `authorized`, `denied`, `restricted`, `limited`; use `.isGranted` for a simple “can use” check.

For more detail, see **PermissionManager.swift** and Apple’s [Requesting access to protected resources](https://developer.apple.com/documentation/uikit/requesting-access-to-protected-resources).
