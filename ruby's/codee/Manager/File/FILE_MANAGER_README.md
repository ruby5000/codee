# File Storage Manager — How to Use

This guide describes the **File Storage Manager** and how to use it for storing, fetching, editing, deleting, renaming, duplicating, and managing files and directories in iOS apps. It wraps `FileManager` with a consistent API and clear error handling.

---

## 1. Overview

**FileStorageManager** provides:

- **Store** — Write `Data`, `String`, or any `Encodable` (JSON) to a path; create parent directories automatically.
- **Fetch** — Read raw `Data`, `String`, or decode `Decodable` from a path or URL.
- **Edit** — Overwrite file content or append to existing files.
- **Delete** — Remove files or directories (with optional recursive directory removal).
- **Rename** — Rename a file or directory in place.
- **Duplicate** — Copy a file to the same directory with a “_copy” suffix or custom name.
- **Copy / Move** — Copy or move items between paths or URLs.
- **Directories** — Create directories (with intermediates), list contents.
- **Metadata** — Check existence, file size, modification date, full attributes.

All APIs are static on `FileStorageManager`. Paths are relative to a **StorageLocation** (Documents, Caches, Temporary, Application Support, or custom URL). No external dependencies; uses Foundation only.

---

## 2. Quick reference

| Need | Use |
|------|-----|
| Store data | `FileStorageManager.store(_ data: Data, at: "folder/file.dat")` |
| Store string | `FileStorageManager.store("hello", at: "folder/note.txt")` |
| Store JSON (Encodable) | `FileStorageManager.store(myObject, at: "config.json")` |
| Fetch data | `let data = try FileStorageManager.fetchData(at: "folder/file.dat")` |
| Fetch string | `let text = try FileStorageManager.fetchString(at: "note.txt")` |
| Fetch JSON (Decodable) | `let obj = try FileStorageManager.fetch(MyType.self, at: "config.json")` |
| Overwrite (edit) | `FileStorageManager.edit("new content", at: "note.txt")` |
| Append | `FileStorageManager.append(" more", to: "log.txt")` |
| Delete file/dir | `try FileStorageManager.delete(at: "path")` |
| Delete directory (recursive) | `try FileStorageManager.removeDirectory(at: "folder", recursive: true)` |
| Remove if exists (no throw) | `FileStorageManager.removeFileIfExists(at: url)` |
| Rename | `try FileStorageManager.rename(at: "old.txt", to: "new.txt")` |
| Duplicate | `let newURL = try FileStorageManager.duplicate(at: "file.txt")` |
| Copy | `try FileStorageManager.copy(from: "a.txt", to: "b.txt")` |
| Move | `try FileStorageManager.move(from: "a.txt", to: "sub/b.txt")` |
| Create directory | `try FileStorageManager.createDirectory(at: "folder/sub")` |
| List contents | `let items = try FileStorageManager.listContents(at: "folder")` |
| Exists? | `FileStorageManager.exists(at: "path")` |
| File size | `FileStorageManager.fileSize(at: "path")` |
| Modification date | `FileStorageManager.modificationDate(at: "path")` |
| Resolve URL | `FileStorageManager.url(for: "path", in: .documents)` |

---

## 3. Storage locations

Paths are resolved relative to a **StorageLocation** (default: `.documents`).

```swift
// Built-in locations
.documents           // App's Documents directory
.caches              // Caches (can be cleared by system)
.temporary           // NSTemporaryDirectory()
.applicationSupport  // Application Support

// Custom base URL
.custom(someURL)
```

Change the default for all calls:

```swift
FileStorageManager.defaultLocation = .caches
```

Or pass the location per call:

```swift
try FileStorageManager.store(data, at: "file.dat", in: .caches)
let list = try FileStorageManager.listContents(at: "exports", in: .documents)
```

---

## 4. Store (write)

### 4.1 Store raw data

```swift
let data = Data([0x00, 0x01, 0x02])
try FileStorageManager.store(data, at: "data/binary.dat")
```

Parent directory `data/` is created if needed. Overwrites if the file exists.

### 4.2 Store string

```swift
try FileStorageManager.store("Hello, world!", at: "notes/hello.txt")
```

Encoded as UTF-8.

### 4.3 Store Encodable (JSON)

```swift
struct Config: Codable {
    let theme: String
    let count: Int
}
let config = Config(theme: "dark", count: 10)
try FileStorageManager.store(config, at: "config.json")
```

Uses `JSONEncoder()` by default; you can pass a custom encoder.

### 4.4 Store at full URL

```swift
let url = FileStorageManager.url(for: "custom/path.txt", in: .documents)
try FileStorageManager.store(data, at: url)
```

### 4.5 Append

Append to an existing file (or create it with that content if it doesn’t exist):

```swift
try FileStorageManager.append("line 1\n", to: "log.txt")
try FileStorageManager.append("line 2\n", to: "log.txt")
```

---

## 5. Fetch (read)

### 5.1 Fetch data

```swift
let data = try FileStorageManager.fetchData(at: "data/binary.dat")
```

Throws `FileStorageManagerError.fileNotFound` or `.notAFile` if the path is a directory.

### 5.2 Fetch string

```swift
let text = try FileStorageManager.fetchString(at: "notes/hello.txt")
```

### 5.3 Fetch and decode (Decodable)

```swift
let config = try FileStorageManager.fetch(Config.self, at: "config.json")
```

Decoding errors are wrapped in `FileStorageManagerError.decodingFailed(_)`.

### 5.4 Fetch from URL

```swift
let url = FileStorageManager.url(for: "config.json", in: .documents)
let data = try FileStorageManager.fetchData(at: url)
let config = try FileStorageManager.fetch(Config.self, at: url)
```

---

## 6. Edit (overwrite / append)

- **Overwrite:** Use `store` or `edit` — they do the same (create parent dirs, overwrite file).
- **Append:** Use `append(_:to:in:)` (see Store section).

```swift
try FileStorageManager.edit("Updated content", at: "notes/hello.txt")
try FileStorageManager.edit(updatedConfig, at: "config.json")
```

---

## 7. Delete

### 7.1 Delete file or empty directory

```swift
try FileStorageManager.delete(at: "old.txt")
try FileStorageManager.delete(at: "empty_folder")
```

### 7.2 Delete directory and its contents

```swift
try FileStorageManager.removeDirectory(at: "folder", recursive: true)
```

### 7.3 Remove if exists (no throw)

Use when you don’t care if the file exists:

```swift
FileStorageManager.removeFileIfExists(at: url)
FileStorageManager.removeFileIfExists(at: "temp.txt", in: .temporary)
```

---

## 8. Rename

Renames in the same parent directory:

```swift
try FileStorageManager.rename(at: "old_name.txt", to: "new_name.txt")
// Or with URL:
try FileStorageManager.rename(at: fileURL, to: "new_name.txt")
```

---

## 9. Duplicate

Creates a copy in the same directory. Default name: original name with `_copy` before the extension (e.g. `file_copy.txt`).

```swift
let newURL = try FileStorageManager.duplicate(at: "document.pdf")
// Custom name:
let customURL = try FileStorageManager.duplicate(at: "doc.pdf", to: "doc_backup.pdf")
```

---

## 10. Copy and move

### 10.1 Copy

```swift
try FileStorageManager.copy(from: "source.txt", to: "backup/source.txt")
// With URLs:
try FileStorageManager.copy(from: sourceURL, to: destURL)
```

Destination parent directory is created if needed.

### 10.2 Move

```swift
try FileStorageManager.move(from: "old/source.txt", to: "new/source.txt")
try FileStorageManager.move(from: sourceURL, to: destURL)
```

---

## 11. Directories

### 11.1 Create directory

Creates intermediate directories as needed. No-op if the directory already exists.

```swift
try FileStorageManager.createDirectory(at: "exports/2024/jan")
```

### 11.2 List contents

Returns `[FileItem]` (name, url, isDirectory, size, modificationDate). Skips hidden files.

```swift
let items = try FileStorageManager.listContents(at: "documents")
for item in items {
    print("\(item.name) \(item.isDirectory ? "(dir)" : "") \(item.size) bytes")
}
```

---

## 12. Existence and metadata

### 12.1 Exists

```swift
if FileStorageManager.exists(at: "config.json") {
    // ...
}
```

### 12.2 Is directory

```swift
let isDir = FileStorageManager.isDirectory(at: "folder")
```

### 12.3 File size

```swift
if let size = FileStorageManager.fileSize(at: "video.mp4") {
    print("\(size) bytes")
}
```

### 12.4 Modification date

```swift
if let date = FileStorageManager.modificationDate(at: "log.txt") {
    print(date)
}
```

### 12.5 Full attributes

```swift
let attrs = try FileStorageManager.attributes(at: url)
// e.g. .size, .modificationDate, .type, etc.
```

---

## 13. Resolving paths

Get the full URL for a relative path:

```swift
let url = FileStorageManager.url(for: "folder/file.txt", in: .documents)
// Use url with other APIs or system APIs
```

---

## 14. Errors

All throwing APIs use **FileStorageManagerError**:

| Case | When |
|------|------|
| `invalidPath` | Invalid path/URL |
| `fileNotFound` | File does not exist |
| `directoryNotFound` | Directory does not exist |
| `cannotCreateDirectory(url)` | Failed to create directory |
| `writeFailed(url)` | Write failed |
| `readFailed(url)` | Read failed |
| `deleteFailed(url)` | Delete failed |
| `moveFailed(source:destination:)` | Move failed |
| `copyFailed(source:destination:)` | Copy failed |
| `encodingFailed` | String/Encodable encoding failed |
| `decodingFailed(Error)` | String/Decodable decoding failed |
| `notAFile(url)` | Path is a directory when a file was expected |
| `notADirectory(url)` | Path is a file when a directory was expected |
| `fileAlreadyExists(url)` | Optional; used if you add “no overwrite” APIs |

Handle in code:

```swift
do {
    let data = try FileStorageManager.fetchData(at: "missing.txt")
} catch FileStorageManagerError.fileNotFound {
    // create or use default
} catch {
    print(error.localizedDescription)
}
```

---

## 15. Async usage

To run file operations off the main thread without blocking:

```swift
let data = try await FileStorageManager.performAsync {
    try FileStorageManager.fetchData(at: "large.bin")
}
```

The manager uses an internal serial queue for `performAsync`; heavy work can be wrapped in this call.

---

## 16. FileItem

Returned by `listContents`:

```swift
public struct FileItem {
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let size: Int64
    public let modificationDate: Date?
}
```

---

## 17. Summary

- **Store:** `store(_:at:in:)` for Data/String/Encodable; `append(_:to:in:)` to append.
- **Fetch:** `fetchData`, `fetchString`, `fetch(_:at:in:)` for Decodable.
- **Edit:** Use `store`/`edit` to overwrite; `append` to add at end.
- **Delete:** `delete(at:)` for file/empty dir; `removeDirectory(at:recursive:)` for dir and contents; `removeFileIfExists` when you don’t need to throw.
- **Rename:** `rename(at:to:)` (path or URL).
- **Duplicate:** `duplicate(at:to:)` (path or URL); returns new file URL.
- **Copy / Move:** `copy(from:to:)`, `move(from:to:)` (paths or URLs).
- **Directories:** `createDirectory(at:in:)`, `listContents(at:in:)` → `[FileItem]`.
- **Metadata:** `exists`, `isDirectory`, `fileSize`, `modificationDate`, `attributes`.
- **Paths:** `url(for:in:)` to resolve relative path to full URL.
- **Locations:** `.documents`, `.caches`, `.temporary`, `.applicationSupport`, `.custom(URL)`; set `defaultLocation` or pass `in: location` per call.

For more detail, see the inline documentation in **FileStorageManager.swift**.
