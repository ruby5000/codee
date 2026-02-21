# Validator & Formatter — How to Use

Centralized **validation** and **formatting** for emails, URLs, phones, numbers, dates, and strings.

---

## 1. Overview

**Validator** provides:
- Email, URL, phone validation
- Non-empty, length, numeric checks
- URL normalization

**Formatter** provides:
- Phone, currency, number formatting
- Date, datetime, relative time
- String normalization and truncation

---

## 2. Quick Reference

### Validator

| Need | Use |
|------|-----|
| Email valid? | `Validator.isValidEmail(string)` |
| URL valid? | `Validator.isValidURL(string)` |
| Normalize URL | `Validator.normalizeURL(string)` |
| Phone valid? | `Validator.isValidPhone(string)` |
| Non-empty? | `Validator.isNonEmpty(string)` |
| Length in range? | `Validator.isLength(string, min: 1, max: 100)` |
| Numeric? | `Validator.isNumeric(string)` |

### Formatter

| Need | Use |
|------|-----|
| Phone display | `Formatter.formatPhone(string)` |
| Currency | `Formatter.formatCurrency(9.99)` |
| Number | `Formatter.formatNumber(1234.5, decimals: 2)` |
| Compact (1.2K) | `Formatter.formatCompact(1200)` |
| Date | `Formatter.formatDate(date)` |
| DateTime | `Formatter.formatDateTime(date)` |
| Custom date | `Formatter.formatDate(date, format: "yyyy-MM-dd")` |
| Relative ("2h ago") | `Formatter.formatRelative(date)` |
| Truncate | `Formatter.truncate(string, maxLength: 50)` |

---

## 3. Setup

Add **ValidatorFormatter.swift** (and **Validator** folder) to your app target. No dependencies.

---

## 4. Validation Examples

```swift
if Validator.isValidEmail(emailField.text ?? "") {
    // proceed
}

if let url = Validator.normalizeURL(input) {
    openURL(url)
}

guard Validator.isNonEmpty(nameField.text) else {
    showError("Name required")
    return
}
```

---

## 5. Formatting Examples

```swift
label.text = Formatter.formatCurrency(price)
label.text = Formatter.formatCompact(followerCount)  // "1.2K"
label.text = Formatter.formatRelative(postDate)      // "2 hours ago"
label.text = Formatter.truncate(longText, maxLength: 100)
```

---

## 6. Form Validation Helper

```swift
func validateForm() -> [String: String] {
    var errors: [String: String] = [:]
    if !Validator.isValidEmail(email) { errors["email"] = "Invalid email" }
    if !Validator.isNonEmpty(name) { errors["name"] = "Name required" }
    if !Validator.isLength(password, min: 8, max: 50) { errors["password"] = "8-50 chars" }
    return errors
}
```

---

## 7. Summary

- **Validator:** `isValidEmail`, `isValidURL`, `normalizeURL`, `isValidPhone`, `isNonEmpty`, `isLength`, `isNumeric`
- **Formatter:** `formatPhone`, `formatCurrency`, `formatNumber`, `formatCompact`, `formatDate`, `formatDateTime`, `formatRelative`, `truncate`, `normalizeWhitespace`

For more detail, see **ValidatorFormatter.swift**.
