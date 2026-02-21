# Search Manager — How to Use

**Debounced search**, filtering, and search state management.

---

## 1. Overview

**SearchManager** provides:

- **Debounced search** — Delay search until user stops typing.
- **Filter** — Filter arrays by query (single or multiple key paths).
- **Limit** — Cap results.
- **Config** — `debounceInterval`, `minSearchLength`, `maxResults`.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Debounced handler | `SearchManager.makeDebouncedSearch(onSearch: { ... })` |
| Filter by keyPath | `SearchManager.filter(items, query: q, keyPath: \.name)` |
| Filter by keyPaths | `SearchManager.filter(items, query: q, keyPaths: [\.name, \.email])` |
| Filter custom | `SearchManager.filter(items, query: q, predicate: { ... })` |
| Limit results | `SearchManager.limit(results, max: 20)` |

---

## 3. Setup

Add **SearchManager.swift** (and **Search** folder) to your app target. Uses Foundation only (no Combine required for basic usage).

---

## 4. Debounced Search

```swift
let searchHandler = SearchManager.makeDebouncedSearch(minLength: 2) { query in
    performSearch(query)
}

// In textField delegate or binding
searchHandler(searchTextField.text ?? "")
```

---

## 5. Filter Local Data

```swift
let filtered = SearchManager.filter(users, query: searchText, keyPath: \.name)

// Multiple fields
let filtered = SearchManager.filter(users, query: searchText, keyPaths: [\.name, \.email])

// Custom
let filtered = SearchManager.filter(items, query: searchText) { item, q in
    item.title.contains(q) || item.tags.contains(q)
}
```

---

## 6. With Limit

```swift
let results = SearchManager.limit(filtered, max: SearchManager.maxResults ?? 50)
```

---

## 7. UITextField Integration

```swift
class SearchVC: UIViewController {
    private var searchHandler: ((String) -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()
        searchHandler = SearchManager.makeDebouncedSearch { [weak self] query in
            self?.loadResults(query: query)
        }
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    }

    @objc private func searchChanged() {
        searchHandler(searchField.text ?? "")
    }
}
```

---

## 8. Summary

- **Debounce:** `makeDebouncedSearch`, `debounced`
- **Filter:** `filter` (keyPath, keyPaths, predicate)
- **Limit:** `limit`
- **Config:** `debounceInterval`, `minSearchLength`, `maxResults`

For more detail, see **SearchManager.swift**.
