# Localization Manager — How to Use

Centralized **localization** and **language switching**. Manages current language, localized strings, and UI reload when language changes.

---

## 1. Overview

**LocalizationManager** provides:

- **Current language** — Device language if supported, else saved override or default.
- **Set language** — Switch app language and optionally reload root UI.
- **Localized strings** — Get localized string by key.
- **Bundle override** — Uses custom bundle so `NSLocalizedString` respects selected language.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Current language | `LocalizationManager.currentLanguage` |
| Device language | `LocalizationManager.deviceLanguageCode` |
| Set language | `LocalizationManager.setLanguage("hi", reloadUI: true)` |
| Localized string | `LocalizationManager.string("key")` or `LocalizationManager.tr("key")` |
| Supported languages | `LocalizationManager.supportedLanguages` |
| Default language | `LocalizationManager.defaultLanguage` |

---

## 3. Setup

### 3.1 Add to Xcode

Add **LocalizationManager.swift** (and **Localization** folder) to your app target.

### 3.2 Localization Files

Ensure your project has `.lproj` folders for each language, e.g.:

- `en.lproj/Localizable.strings`
- `hi.lproj/Localizable.strings`
- `es.lproj/Localizable.strings`

### 3.3 Configure Supported Languages

```swift
// Optional: customize at app launch
LocalizationManager.supportedLanguages = ["en", "hi", "es"]
LocalizationManager.defaultLanguage = "en"
LocalizationManager.storageKey = "SelectedAppLanguage"
```

---

## 4. Get Current Language

```swift
let lang = LocalizationManager.currentLanguage  // "en", "hi", etc.
let deviceLang = LocalizationManager.deviceLanguageCode  // From system
```

---

## 5. Set Language

### 5.1 With UI Reload

When user picks a language in settings, reload the app root so all screens use the new language:

```swift
LocalizationManager.setLanguage("hi", reloadUI: true)
```

### 5.2 Without UI Reload

If you only need to change the stored preference (e.g. for next launch):

```swift
LocalizationManager.setLanguage("es", reloadUI: false)
```

---

## 6. Localized Strings

### 6.1 Using LocalizationManager

```swift
let text = LocalizationManager.string("welcome_message")
let short = LocalizationManager.tr("welcome_message")
```

### 6.2 With Table Name

```swift
let text = LocalizationManager.string("key", tableName: "Settings")
```

### 6.3 NSLocalizedString

After calling `Bundle.setLanguage(...)` (done inside `setLanguage`), `NSLocalizedString` will use the selected language:

```swift
let text = NSLocalizedString("welcome_message", comment: "")
```

---

## 7. Localizable.strings Format

```
// en.lproj/Localizable.strings
"welcome_message" = "Welcome!";
"settings_title" = "Settings";

// hi.lproj/Localizable.strings
"welcome_message" = "स्वागत है!";
"settings_title" = "सेटिंग्स";
```

---

## 8. Language Picker Example

```swift
let languages = ["en": "English", "hi": "हिन्दी", "es": "Español"]

func showLanguagePicker() {
    let alert = UIAlertController(title: "Select Language", message: nil, preferredStyle: .actionSheet)
    for (code, name) in languages {
        alert.addAction(UIAlertAction(title: name, style: .default) { _ in
            LocalizationManager.setLanguage(code, reloadUI: true)
        })
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
}
```

---

## 9. Integration with LanguageManager

If you have an existing **LanguageManager** class:

1. **Replace** — Use LocalizationManager instead; migrate call sites.
2. **Wrap** — Keep LanguageManager as a thin wrapper that delegates to LocalizationManager.
3. **Coexist** — Use both during migration; align `storageKey` and `supportedLanguages`.

---

## 10. Summary

- **Current language:** `currentLanguage`, `deviceLanguageCode`.
- **Set language:** `setLanguage(_:reloadUI:)`.
- **Strings:** `string(_:tableName:value:)`, `tr(_:tableName:)`.
- **Config:** `supportedLanguages`, `defaultLanguage`, `storageKey`.

For more detail, see **LocalizationManager.swift**.
