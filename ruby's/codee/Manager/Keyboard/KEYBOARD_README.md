# Keyboard Manager — How to Use

**Keyboard observers**: frame, height, show/hide.

---

## 1. Overview

**KeyboardManager** provides:

- **Frame** — keyboardFrame, keyboardHeight
- **Visibility** — isVisible
- **Handlers** — onWillShow, onWillHide, onFrameChange
- **Animation** — animationDuration, animationCurve
- **ScrollView** — adjustScrollView helper

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Start observe | `KeyboardManager.startObserving()` |
| Stop observe | `KeyboardManager.stopObserving()` |
| Keyboard height | `KeyboardManager.keyboardHeight` |
| Is visible? | `KeyboardManager.isVisible` |
| On show | `KeyboardManager.onWillShow = { frame, duration in ... }` |
| On hide | `KeyboardManager.onWillHide = { duration in ... }` |
| Adjust scroll | `KeyboardManager.adjustScrollView(scrollView, for: frame, in: view)` |

---

## 3. Setup

```swift
// AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    KeyboardManager.startObserving()
    return true
}
```

---

## 4. Usage

```swift
KeyboardManager.onWillShow = { frame, duration in
    UIView.animate(withDuration: duration) {
        self.bottomConstraint.constant = frame.height
        self.view.layoutIfNeeded()
    }
}

KeyboardManager.onWillHide = { duration in
    UIView.animate(withDuration: duration) {
        self.bottomConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
}

// In scroll view controller
KeyboardManager.onFrameChange = { [weak self] frame in
    guard let self = self else { return }
    KeyboardManager.adjustScrollView(self.scrollView, for: frame, in: self.view)
}
```

---

## 5. Summary

- **Observe:** startObserving, stopObserving
- **State:** keyboardFrame, keyboardHeight, isVisible
- **Handlers:** onWillShow, onWillHide, onFrameChange
- **Helper:** adjustScrollView

For more detail, see **KeyboardManager.swift**.
