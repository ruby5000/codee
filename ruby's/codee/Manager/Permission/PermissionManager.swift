//
//  PermissionManager.swift
//  Centralizes iOS permission checks and requests. Keeps permission logic out of view controllers.
//
//  See PERMISSION_MANAGER_README.md for usage and required Info.plist keys.
//  Requires: UIKit (iOS).
//

import Foundation
import UIKit
import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import Contacts
import EventKit
import Speech
import LocalAuthentication
import MediaPlayer
import CoreMotion

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

// MARK: - PermissionKind

/// All supported iOS permission types. Add Info.plist usage description for each you use.
public enum PermissionKind: CaseIterable, Sendable {
    case camera
    case microphone
    case photos
    case photosAddOnly
    case locationWhenInUse
    case locationAlways
    case notifications
    case bluetooth
    case contacts
    case calendar
    case reminders
    case speechRecognition
    case faceID
    case motion
    case mediaLibrary
    case tracking
}

// MARK: - PermissionStatus

/// Normalized status across all permission types.
public enum PermissionStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case limited  // e.g. Photos limited selection

    public var isGranted: Bool {
        self == .authorized || self == .limited
    }
}

// MARK: - PermissionManager

/// Centralized permission checks and requests. Use from a service or coordinator, not from view controllers directly.
public enum PermissionManager {

    private static let locationDelegate = LocationPermissionDelegate()
    fileprivate static let locationManager: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy = kCLLocationAccuracyBest
        return m
    }()

    // MARK: - Status (async to avoid main-thread I/O warnings on iOS 18+)

    /// Returns current status for the given permission. Prefer calling off main thread for status-only checks.
    public static func status(for kind: PermissionKind) async -> PermissionStatus {
        switch kind {
        case .camera:
            return await statusCamera()
        case .microphone:
            return await statusMicrophone()
        case .photos:
            return await statusPhotos()
        case .photosAddOnly:
            return await statusPhotosAddOnly()
        case .locationWhenInUse, .locationAlways:
            return statusLocation(always: kind == .locationAlways)
        case .notifications:
            return await statusNotifications()
        case .bluetooth:
            return statusBluetooth()
        case .contacts:
            return await statusContacts()
        case .calendar:
            return await statusCalendar()
        case .reminders:
            return await statusReminders()
        case .speechRecognition:
            return await statusSpeechRecognition()
        case .faceID:
            return statusFaceID()
        case .motion:
            return await statusMotion()
        case .mediaLibrary:
            return await statusMediaLibrary()
        case .tracking:
            return statusTracking()
        }
    }

    /// Request permission. Shows system alert if status is .notDetermined. Returns the resulting status.
    public static func request(_ kind: PermissionKind) async -> PermissionStatus {
        let current = await status(for: kind)
        if current != .notDetermined {
            return current
        }
        switch kind {
        case .camera:
            return await requestCamera()
        case .microphone:
            return await requestMicrophone()
        case .photos:
            return await requestPhotos()
        case .photosAddOnly:
            return await requestPhotosAddOnly()
        case .locationWhenInUse:
            return await requestLocationWhenInUse()
        case .locationAlways:
            return await requestLocationAlways()
        case .notifications:
            return await requestNotifications()
        case .bluetooth:
            return await requestBluetooth()
        case .contacts:
            return await requestContacts()
        case .calendar:
            return await requestCalendar()
        case .reminders:
            return await requestReminders()
        case .speechRecognition:
            return await requestSpeechRecognition()
        case .faceID:
            return await requestFaceID()
        case .motion:
            return await requestMotion()
        case .mediaLibrary:
            return await requestMediaLibrary()
        case .tracking:
            return await requestTracking()
        }
    }

    /// Request only if status is .notDetermined; otherwise return current status. Convenience to avoid duplicate prompts.
    public static func requestIfNeeded(_ kind: PermissionKind) async -> PermissionStatus {
        let current = await status(for: kind)
        if current != .notDetermined { return current }
        return await request(kind)
    }

    // MARK: - Camera

    private static func statusCamera() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                continuation.resume(returning: mapAVStatus(status))
            }
        }
    }

    private static func requestCamera() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.global(qos: .userInitiated).async {
                    let status = AVCaptureDevice.authorizationStatus(for: .video)
                    continuation.resume(returning: mapAVStatus(status))
                }
            }
        }
    }

    private static func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }

    // MARK: - Microphone

    private static func statusMicrophone() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = AVCaptureDevice.authorizationStatus(for: .audio)
                continuation.resume(returning: mapAVStatus(status))
            }
        }
    }

    private static func requestMicrophone() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.global(qos: .userInitiated).async {
                    let status = AVCaptureDevice.authorizationStatus(for: .audio)
                    continuation.resume(returning: mapAVStatus(status))
                }
            }
        }
    }

    // MARK: - Photos

    private static func statusPhotos() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if #available(iOS 14, *) {
                    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                    continuation.resume(returning: mapPHStatus(status))
                } else {
                    let status = PHPhotoLibrary.authorizationStatus()
                    continuation.resume(returning: mapPHStatus(status))
                }
            }
        }
    }

    private static func requestPhotos() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.global(qos: .userInitiated).async {
                        continuation.resume(returning: mapPHStatus(status))
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.global(qos: .userInitiated).async {
                        continuation.resume(returning: mapPHStatus(status))
                    }
                }
            }
        }
    }

    private static func statusPhotosAddOnly() async -> PermissionStatus {
        guard #available(iOS 14, *) else {
            return await statusPhotos()
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
                continuation.resume(returning: mapPHStatus(status))
            }
        }
    }

    private static func requestPhotosAddOnly() async -> PermissionStatus {
        guard #available(iOS 14, *) else {
            return await requestPhotos()
        }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.global(qos: .userInitiated).async {
                    continuation.resume(returning: mapPHStatus(status))
                }
            }
        }
    }

    private static func mapPHStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized, .limited: return status == .limited ? .limited : .authorized
        @unknown default: return .denied
        }
    }

    // MARK: - Location

    private static func statusLocation(always: Bool) -> PermissionStatus {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedWhenInUse: return always ? .denied : .authorized
        case .authorizedAlways: return .authorized
        @unknown default: return .denied
        }
    }

    private static func requestLocationWhenInUse() async -> PermissionStatus {
        await locationDelegate.requestWhenInUse()
    }

    private static func requestLocationAlways() async -> PermissionStatus {
        await locationDelegate.requestAlways()
    }

    // MARK: - Notifications

    private static func statusNotifications() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let status: PermissionStatus
                switch settings.authorizationStatus {
                case .notDetermined: status = .notDetermined
                case .denied: status = .denied
                case .authorized, .provisional, .ephemeral: status = .authorized
                @unknown default: status = .denied
                }
                continuation.resume(returning: status)
            }
        }
    }

    private static func requestNotifications() async -> PermissionStatus {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    // MARK: - Bluetooth

    private static func statusBluetooth() -> PermissionStatus {
        #if canImport(CoreBluetooth)
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .allowedAlways: return .authorized
            @unknown default: return .denied
            }
        }
        #endif
        return .authorized
    }

    private static func requestBluetooth() async -> PermissionStatus {
        #if canImport(CoreBluetooth)
        return await BluetoothPermissionHelper.request()
        #else
        return .authorized
        #endif
    }

    // MARK: - Contacts

    private static func statusContacts() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = CNContactStore.authorizationStatus(for: .contacts)
                continuation.resume(returning: mapCNAuthorizationStatus(status))
            }
        }
    }

    private static func requestContacts() async -> PermissionStatus {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    private static func mapCNAuthorizationStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }

    // MARK: - Calendar

    private static func statusCalendar() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = EKEventStore.authorizationStatus(for: .event)
                continuation.resume(returning: mapEKStatus(status))
            }
        }
    }

    private static func requestCalendar() async -> PermissionStatus {
        let store = EKEventStore()
        if #available(iOS 17.0, *) {
            do {
                let granted = try await store.requestFullAccessToEvents()
                return granted ? .authorized : .denied
            } catch {
                return .denied
            }
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    DispatchQueue.global(qos: .userInitiated).async {
                        let status = EKEventStore.authorizationStatus(for: .event)
                        continuation.resume(returning: mapEKStatus(status))
                    }
                }
            }
        }
    }

    // MARK: - Reminders

    private static func statusReminders() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = EKEventStore.authorizationStatus(for: .reminder)
                continuation.resume(returning: mapEKStatus(status))
            }
        }
    }

    private static func requestReminders() async -> PermissionStatus {
        let store = EKEventStore()
        if #available(iOS 17.0, *) {
            do {
                let granted = try await store.requestFullAccessToReminders()
                return granted ? .authorized : .denied
            } catch {
                return .denied
            }
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, _ in
                    DispatchQueue.global(qos: .userInitiated).async {
                        let status = EKEventStore.authorizationStatus(for: .reminder)
                        continuation.resume(returning: mapEKStatus(status))
                    }
                }
            }
        }
    }

    private static func mapEKStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        case .fullAccess, .writeOnly: return .authorized
        @unknown default: return .denied
        }
    }

    // MARK: - Speech Recognition

    private static func statusSpeechRecognition() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = SFSpeechRecognizer.authorizationStatus()
                switch status {
                case .notDetermined: continuation.resume(returning: .notDetermined)
                case .denied: continuation.resume(returning: .denied)
                case .restricted: continuation.resume(returning: .restricted)
                case .authorized: continuation.resume(returning: .authorized)
                @unknown default: continuation.resume(returning: .denied)
                }
            }
        }
    }

    private static func requestSpeechRecognition() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.global(qos: .userInitiated).async {
                    switch status {
                    case .notDetermined: continuation.resume(returning: .notDetermined)
                    case .denied: continuation.resume(returning: .denied)
                    case .restricted: continuation.resume(returning: .restricted)
                    case .authorized: continuation.resume(returning: .authorized)
                    @unknown default: continuation.resume(returning: .denied)
                    }
                }
            }
        }
    }

    // MARK: - Face ID

    private static func statusFaceID() -> PermissionStatus {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if canEvaluate { return .authorized }
        if let e = error {
            switch e.code {
            case LAError.biometryNotAvailable.rawValue, LAError.biometryNotEnrolled.rawValue: return .denied
            case LAError.biometryLockout.rawValue: return .denied
            default: return .notDetermined
            }
        }
        return .notDetermined
    }

    private static func requestFaceID() async -> PermissionStatus {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return statusFaceID()
        }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate") { success, _ in
                continuation.resume(returning: success ? .authorized : .denied)
            }
        }
    }

    // MARK: - Motion

    private static func statusMotion() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = CMMotionActivityManager.authorizationStatus()
                switch status {
                case .notDetermined: continuation.resume(returning: .notDetermined)
                case .denied: continuation.resume(returning: .denied)
                case .restricted: continuation.resume(returning: .restricted)
                case .authorized: continuation.resume(returning: .authorized)
                @unknown default: continuation.resume(returning: .denied)
                }
            }
        }
    }

    private static func requestMotion() async -> PermissionStatus {
        let manager = CMMotionActivityManager()
        return await withCheckedContinuation { continuation in
            let now = Date()
            manager.queryActivityStarting(from: now, to: now, to: .main) { _, error in
                let status = CMMotionActivityManager.authorizationStatus()
                switch status {
                case .notDetermined: continuation.resume(returning: .notDetermined)
                case .denied: continuation.resume(returning: .denied)
                case .restricted: continuation.resume(returning: .restricted)
                case .authorized: continuation.resume(returning: .authorized)
                @unknown default: continuation.resume(returning: .denied)
                }
            }
        }
    }

    // MARK: - Media Library

    private static func statusMediaLibrary() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = MPMediaLibrary.authorizationStatus()
                switch status {
                case .notDetermined: continuation.resume(returning: .notDetermined)
                case .denied: continuation.resume(returning: .denied)
                case .restricted: continuation.resume(returning: .restricted)
                case .authorized: continuation.resume(returning: .authorized)
                @unknown default: continuation.resume(returning: .denied)
                }
            }
        }
    }

    private static func requestMediaLibrary() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                DispatchQueue.global(qos: .userInitiated).async {
                    switch status {
                    case .notDetermined: continuation.resume(returning: .notDetermined)
                    case .denied: continuation.resume(returning: .denied)
                    case .restricted: continuation.resume(returning: .restricted)
                    case .authorized: continuation.resume(returning: .authorized)
                    @unknown default: continuation.resume(returning: .denied)
                    }
                }
            }
        }
    }

    // MARK: - Tracking (ATT)

    private static func statusTracking() -> PermissionStatus {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .authorized: return .authorized
            @unknown default: return .denied
            }
        }
        #endif
        return .authorized
    }

    private static func requestTracking() async -> PermissionStatus {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, *) {
            let status = await ATTrackingManager.requestTrackingAuthorization { _ in }
            switch status {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .authorized: return .authorized
            @unknown default: return .denied
            }
        }
        #endif
        return .authorized
    }
}

// MARK: - Location delegate (async request)

private final class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private var whenInUseContinuation: CheckedContinuation<PermissionStatus, Never>?
    private var alwaysContinuation: CheckedContinuation<PermissionStatus, Never>?

    func requestWhenInUse() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            whenInUseContinuation = continuation
            PermissionManager.locationManager.delegate = self
            PermissionManager.locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestAlways() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            alwaysContinuation = continuation
            PermissionManager.locationManager.delegate = self
            PermissionManager.locationManager.requestAlwaysAuthorization()
        }
    }

    private func mapCLStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        @unknown default: return .denied
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        let result = mapCLStatus(status)
        if let cont = whenInUseContinuation {
            whenInUseContinuation = nil
            alwaysContinuation = nil
            cont.resume(returning: result)
        } else if let cont = alwaysContinuation {
            alwaysContinuation = nil
            cont.resume(returning: result)
        }
        manager.delegate = nil
    }
}

// MARK: - Bluetooth helper (trigger prompt and wait for state)

#if canImport(CoreBluetooth)
private final class BluetoothPermissionHelper: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<PermissionStatus, Never>?
    private var central: CBCentralManager?

    static func request() async -> PermissionStatus {
        let helper = BluetoothPermissionHelper()
        return await helper.run()
    }

    private func run() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            central = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let cont = continuation else { return }
        continuation = nil
        let status: PermissionStatus
        switch central.state {
        case .unauthorized, .unsupported:
            if #available(iOS 13.1, *) {
                status = CBManager.authorization == .denied ? .denied : .restricted
            } else {
                status = .denied
            }
        case .poweredOff, .poweredOn, .resetting:
            status = #available(iOS 13.1, *) ? (CBManager.authorization == .allowedAlways ? .authorized : .denied) : .authorized
        default:
            status = #available(iOS 13.1, *) ? (CBManager.authorization == .allowedAlways ? .authorized : .notDetermined) : .authorized
        }
        cont.resume(returning: status)
    }
}
#endif
