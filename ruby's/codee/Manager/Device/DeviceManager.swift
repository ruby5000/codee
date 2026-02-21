//
//  DeviceManager.swift
//  Device info: model, OS, screen, identifier, capabilities.
//
//  See DEVICE_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - DeviceManager

/// Device info and capabilities.
public enum DeviceManager {

    /// Device model (e.g. "iPhone14,2").
    public static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    /// Device model name (e.g. "iPhone 13 Pro").
    public static var modelName: String {
        UIDevice.current.model
    }

    /// System name (e.g. "iOS").
    public static var systemName: String {
        UIDevice.current.systemName
    }

    /// System version (e.g. "17.0").
    public static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    /// Device name (user-set, e.g. "John's iPhone").
    public static var deviceName: String {
        UIDevice.current.name
    }

    /// Screen bounds.
    public static var screenBounds: CGRect {
        UIScreen.main.bounds
    }

    /// Screen scale.
    public static var screenScale: CGFloat {
        UIScreen.main.scale
    }

    /// Screen width (points).
    public static var screenWidth: CGFloat {
        screenBounds.width
    }

    /// Screen height (points).
    public static var screenHeight: CGFloat {
        screenBounds.height
    }

    /// Whether device is iPhone.
    public static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    /// Whether device is iPad.
    public static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Whether device is simulator.
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Battery level (0...1 or -1 if unknown).
    public static var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        defer { UIDevice.current.isBatteryMonitoringEnabled = false }
        return UIDevice.current.batteryLevel
    }

    /// Low power mode.
    public static var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// App version.
    public static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Build number.
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
