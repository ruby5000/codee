# Location Manager — How to Use

**Location**: current location, updates, geocoding.

---

## 1. Overview

**LocationManager** provides:

- **Request location** — One-shot async
- **Updates** — Continuous with callback
- **Geocoding** — Reverse (coords → placemark), forward (address → coords)
- **Status** — authorizationStatus, isAuthorized

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Request location | `let loc = try await LocationManager.requestLocation()` |
| Start updates | `LocationManager.startUpdatingLocation { loc in ... }` |
| Stop updates | `LocationManager.stopUpdatingLocation()` |
| Reverse geocode | `let place = try await LocationManager.reverseGeocode(location: loc)` |
| Geocode address | `let loc = try await LocationManager.geocode(address: "Paris")` |
| Is authorized? | `LocationManager.isAuthorized` |
| Current (cached) | `LocationManager.currentLocation` |

---

## 3. Setup

### 3.1 Info.plist

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby content.</string>
```

### 3.2 Request Permission First

```swift
let status = await PermissionManager.request(.locationWhenInUse)
guard status.isGranted else { return }
let loc = try await LocationManager.requestLocation()
```

---

## 4. Usage

```swift
// One-shot
let location = try await LocationManager.requestLocation()

// Continuous
LocationManager.startUpdatingLocation { loc in
    updateMap(loc)
}

// Reverse geocode
let placemark = try await LocationManager.reverseGeocode(location: location)
let city = placemark.locality
```

---

## 5. Summary

- **Location:** requestLocation, startUpdatingLocation, stopUpdatingLocation
- **Geocode:** reverseGeocode, geocode
- **Status:** authorizationStatus, isAuthorized, currentLocation

For more detail, see **LocationManager.swift**.
