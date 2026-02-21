# Auth Manager / Session Manager — How to Use

Centralized **auth state** and **session handling**. Tracks current user, tokens, and login status. Integrates with Google, Apple, Facebook, and Firebase Auth.

---

## 1. Overview

**SessionManager** provides:

- **Session state** — `isLoggedIn`, `currentUserId`, `currentUserEmail`, `accessToken`.
- **Update session** — Call after successful login from any auth provider.
- **Logout** — Clear session and optionally run cleanup (Firebase signOut, etc.).
- **Notifications** — Observe `sessionDidChangeNotification` for UI updates.

Use **SessionManager** for app-wide auth state. Use **GoogleAuthManager**, **AppleAuthManager**, **FacebookAuthManager** for the actual sign-in flows.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Is user logged in? | `SessionManager.isLoggedIn` |
| User ID | `SessionManager.currentUserId` |
| User email | `SessionManager.currentUserEmail` |
| User name | `SessionManager.currentUserName` |
| Access token | `SessionManager.accessToken` |
| Session state | `SessionManager.state` |
| Set session (after login) | `SessionManager.setSession(userId:email:name:accessToken:)` |
| Update session | `SessionManager.updateSession(email:name:accessToken:)` |
| Logout | `SessionManager.logout(additionalCleanup:)` |
| Observe changes | `NotificationCenter` + `sessionDidChangeNotification` |

---

## 3. Setup

### 3.1 Add to Xcode

Add **SessionManager.swift** (and **Auth** folder) to your app target.

### 3.2 Integrate with Auth Providers

After successful login in **GoogleAuthManager**, **AppleAuthManager**, or **FacebookAuthManager**, call:

```swift
SessionManager.setSession(
    userId: firebaseUser.uid,
    email: firebaseUser.email,
    name: firebaseUser.displayName,
    accessToken: accessToken  // if you have it
)
SessionManager.notifySessionChanged()
```

---

## 4. After Login

### 4.1 Google Sign-In

```swift
GoogleAuthManager.shared.login(from: self) { result in
    switch result {
    case .success(let user):
        SessionManager.setSession(
            userId: user.uid,
            email: user.email,
            name: user.displayName,
            accessToken: nil  // or from Google token
        )
        SessionManager.notifySessionChanged()
        // Navigate to home
    case .failure(let error):
        // Show error
    }
}
```

### 4.2 Apple Sign-In

```swift
// In AppleAuthManager delegate:
func didCompleteAppleSignIn(email: String?) {
    if let user = Auth.auth().currentUser {
        SessionManager.setSession(
            userId: user.uid,
            email: email ?? user.email,
            name: UserDefaults.standard.string(forKey: Constants.UD.USER_FULL_NAME)
        )
        SessionManager.notifySessionChanged()
    }
}
```

### 4.3 Facebook Sign-In

Same pattern: after Firebase Auth success, call `SessionManager.setSession(...)` and `notifySessionChanged()`.

---

## 5. Logout

### 5.1 Basic Logout

```swift
SessionManager.logout()
SessionManager.notifySessionChanged()
// Navigate to login screen
```

### 5.2 Logout with Firebase + Google Sign-Out

```swift
SessionManager.logout(additionalCleanup: {
    try? Auth.auth().signOut()
    GIDSignIn.sharedInstance.signOut()
})
SessionManager.notifySessionChanged()
```

---

## 6. Check Auth State

### 6.1 Guard for Logged-In Screens

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    guard SessionManager.isLoggedIn else {
        // Redirect to login
        return
    }
    loadUserData()
}
```

### 6.2 Get User Info

```swift
if let userId = SessionManager.currentUserId {
    fetchProfile(userId: userId)
}
if let email = SessionManager.currentUserEmail {
    label.text = email
}
```

### 6.3 Session State Enum

```swift
switch SessionManager.state {
case .loggedOut:
    showLoginScreen()
case .loggedIn(let userId, let email):
    showHome(userId: userId, email: email)
}
```

---

## 7. Observe Session Changes

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(sessionDidChange),
    name: SessionManager.sessionDidChangeNotification,
    object: nil
)

@objc private func sessionDidChange() {
    if SessionManager.isLoggedIn {
        // Refresh UI, load data
    } else {
        // Show login
    }
}
```

---

## 8. Custom UserDefaults Suite

If you use an app group:

```swift
if let suite = UserDefaults(suiteName: "group.com.yourapp") {
    SessionManager.userDefaults = suite
}
```

---

## 9. Integration with Existing UD Keys

If you already store auth data in `Constants.UD` (e.g. `USER_ACCESS_TOKEN`, `IS_USER_AUTH`), you can:

1. **Dual-write** — Update both SessionManager and your UD keys on login.
2. **Migrate** — Gradually move to SessionManager and read from it.
3. **Alias** — Keep UD keys but populate them from SessionManager in a bridge layer.

---

## 10. Summary

- **State:** `isLoggedIn`, `currentUserId`, `currentUserEmail`, `currentUserName`, `accessToken`, `state`.
- **Set session:** `setSession(userId:email:name:accessToken:)` after login.
- **Logout:** `logout(additionalCleanup:)` + `notifySessionChanged()`.
- **Observe:** `sessionDidChangeNotification`.
- **Integrate:** Call SessionManager from GoogleAuthManager, AppleAuthManager, FacebookAuthManager after successful Firebase Auth.

For more detail, see **SessionManager.swift**.
