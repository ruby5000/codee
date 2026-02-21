//
//  LocationManager.swift
//  Centralized location: current location, updates, geocoding.
//
//  See LOCATION_README.md for setup and usage.
//  Requires: CoreLocation, Info.plist keys.
//

import Foundation
import CoreLocation

// MARK: - LocationManager

/// Centralized location handling.
public enum LocationManager {

    private static let manager: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy = kCLLocationAccuracyBest
        m.distanceFilter = 10
        return m
    }()

    /// Delegate wrapper for async/await.
    fileprivate static var continuation: CheckedContinuation<CLLocation, Error>?

    /// Current location (cached). Nil until fetched.
    public static private(set) var currentLocation: CLLocation?

    /// Authorization status.
    public static var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    /// Whether location is authorized.
    public static var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return true
        default: return false
        }
    }

    // MARK: - Request

    /// Requests location. Call after PermissionManager.request(.locationWhenInUse).
    public static func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            Self.continuation = continuation
            manager.delegate = LocationDelegateWrapper.shared
            manager.requestLocation()
        }
    }

    /// Starts continuous location updates.
    public static func startUpdatingLocation(onUpdate: @escaping (CLLocation) -> Void) {
        manager.delegate = LocationDelegateWrapper.shared
        LocationDelegateWrapper.shared.onUpdate = onUpdate
        manager.startUpdatingLocation()
    }

    /// Stops updates.
    public static func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        LocationDelegateWrapper.shared.onUpdate = nil
    }

    // MARK: - Geocoding

    /// Reverse geocode: coordinates to placemark.
    public static func reverseGeocode(location: CLLocation) async throws -> CLPlacemark {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let first = placemarks.first else {
            throw NSError(domain: "LocationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No placemark"])
        }
        return first
    }

    /// Geocode: address string to coordinates.
    public static func geocode(address: String) async throws -> CLLocation {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let loc = placemarks.first?.location else {
            throw NSError(domain: "LocationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No location"])
        }
        return loc
    }
}

// MARK: - Delegate Wrapper

private final class LocationDelegateWrapper: NSObject, CLLocationManagerDelegate {
    static let shared = LocationDelegateWrapper()
    var onUpdate: ((CLLocation) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        LocationManager.currentLocation = loc
        if let cont = LocationManager.continuation {
            LocationManager.continuation = nil
            cont.resume(returning: loc)
        }
        onUpdate?(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let cont = LocationManager.continuation {
            LocationManager.continuation = nil
            cont.resume(throwing: error)
        }
    }

}
