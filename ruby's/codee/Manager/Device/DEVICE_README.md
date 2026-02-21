# Device Manager — How to Use

**Device info**: model, OS, screen, battery, capabilities.

---

## 1. Overview

**DeviceManager** provides:

- **Model** — modelIdentifier, modelName
- **OS** — systemName, systemVersion
- **Screen** — bounds, scale, width, height
- **Idiom** — isPhone, isPad
- **Environment** — isSimulator
- **Battery** — batteryLevel, isLowPowerMode
- **App** — appVersion, buildNumber

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Model ID | `DeviceManager.modelIdentifier` |
| Model name | `DeviceManager.modelName` |
| iOS version | `DeviceManager.systemVersion` |
| Screen size | `DeviceManager.screenWidth`, `screenHeight` |
| Is phone? | `DeviceManager.isPhone` |
| Is simulator? | `DeviceManager.isSimulator` |
| Battery | `DeviceManager.batteryLevel`, `isLowPowerMode` |
| App version | `DeviceManager.appVersion` |

---

## 3. Setup

Add **DeviceManager.swift** to your target. Requires UIKit.

---

## 4. Summary

- **Device:** modelIdentifier, modelName, systemName, systemVersion
- **Screen:** screenBounds, screenWidth, screenHeight, screenScale
- **Idiom:** isPhone, isPad, isSimulator
- **Battery:** batteryLevel, isLowPowerMode
- **App:** appVersion, buildNumber

For more detail, see **DeviceManager.swift**.
