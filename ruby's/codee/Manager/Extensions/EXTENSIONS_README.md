# Extensions Pack — How to Use

Common **extensions** for String, Array, Date, Optional, UIView, and UIViewController.

---

## 1. Overview

**ExtensionsPack** provides:

- **String** — Safe subscript, nilIfEmpty, asURLString, replacing
- **Array** — Safe subscript, uniqued, chunked
- **Date** — startOfDay, endOfDay, isToday, adding(days:)
- **Optional** — isNilOrEmpty (for Collection)
- **UIView** — roundCorners, addBorder, loadFromNib
- **UIViewController** — showAlert, hideKeyboardOnTap

---

## 2. Quick Reference

### String
| Need | Use |
|------|-----|
| Safe char | `string[safe: 5]` |
| Nil if empty | `string.nilIfEmpty` |
| Add https | `string.asURLString` |

### Array
| Need | Use |
|------|-----|
| Safe index | `array[safe: 10]` |
| Unique | `array.uniqued` or `array.uniqued(by: \.id)` |
| Chunk | `array.chunked(into: 5)` |

### Date
| Need | Use |
|------|-----|
| Start of day | `date.startOfDay` |
| End of day | `date.endOfDay` |
| Is today? | `date.isToday` |
| Add days | `date.adding(days: 7)` |

### UIView
| Need | Use |
|------|-----|
| Round corners | `view.roundCorners(radius: 8)` |
| Border | `view.addBorder(width: 1, color: .gray)` |
| Load nib | `MyView.loadFromNib()` |

### UIViewController
| Need | Use |
|------|-----|
| Alert | `showAlert(title: "Error", message: "Something went wrong")` |
| Hide keyboard | `hideKeyboardOnTap()` |

---

## 3. Setup

Add **ExtensionsPack.swift** (and **Extensions** folder) to your app target. Requires UIKit.

---

## 4. Examples

```swift
// Safe array access
let item = items[safe: index] ?? defaultItem

// Unique by id
let unique = users.uniqued(by: \.id)

// Date range
let start = date.startOfDay
let end = date.endOfDay

// URL string
let url = userInput.asURLString

// Alert
showAlert(title: "Done", message: "Saved successfully")
```

---

## 5. Coexistence with Existing Extensions

If you have `String.swift`, `Array.swift` with overlapping extensions:

- **Merge** — Copy useful extensions into ExtensionsPack, remove duplicates.
- **Keep both** — ExtensionsPack adds new ones; Swift allows multiple extensions.
- **Rename** — Use different method names if there's a conflict.

---

## 6. Summary

- **String:** `[safe:]`, `nilIfEmpty`, `asURLString`, `replacing`
- **Array:** `[safe:]`, `uniqued`, `uniqued(by:)`, `chunked(into:)`
- **Date:** `startOfDay`, `endOfDay`, `isToday`, `adding(days:)`
- **Optional:** `isNilOrEmpty`
- **UIView:** `roundCorners`, `addBorder`, `loadFromNib`
- **UIViewController:** `showAlert`, `hideKeyboardOnTap`

For more detail, see **ExtensionsPack.swift**.
