//
//  LocationService.swift
//  GasProtectionService
//
//  Created by Dima Sunko on 29.12.2025.
//

import Foundation
import CoreLocation
import Combine

/// Сервис для работы с геолокацией и определением адреса
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Singleton

    static let shared = LocationService()

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var isLoadingLocation = false
    @Published var currentAddress = ""

    // MARK: - Initialization

    private override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Public Methods

    /// Запрашивает текущую геолокацию и определяет адрес
    func requestCurrentLocation() {
        isLoadingLocation = true

        // Check location authorization status
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            isLoadingLocation = false
            return
        case .denied, .restricted:
            currentAddress = "Доступ до геолокації заборонено"
            isLoadingLocation = false
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            currentAddress = "Невідома помилка геолокації"
            isLoadingLocation = false
            return
        }

        // Start location updates
        locationManager.startUpdatingLocation()
    }

    // MARK: - Private Methods

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // Включаем поддержку фонового режима
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoadingLocation = false
            return
        }

        // Stop updating location after getting first result
        locationManager.stopUpdatingLocation()

        // Создаём локаль для украинского языка
        let ukrainianLocale = Locale(identifier: "uk_UA")

        // Reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location, preferredLocale: ukrainianLocale) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoadingLocation = false

                if let error = error {
                    self?.currentAddress = "Помилка визначення адреси: \(error.localizedDescription)"
                    return
                }

                if let placemark = placemarks?.first {
                    // Format address in Ukrainian style
                    var addressComponents = [String]()

                    if let streetName = placemark.thoroughfare, let streetNumber = placemark.subThoroughfare {
                        addressComponents.append("вул. \(streetName), \(streetNumber)")
                    } else if let streetName = placemark.thoroughfare {
                        addressComponents.append("вул. \(streetName)")
                    }

                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }

                    if addressComponents.isEmpty {
                        self?.currentAddress = "Адреса не знайдена"
                    } else {
                        self?.currentAddress = addressComponents.joined(separator: ", ")
                    }
                } else {
                    self?.currentAddress = "Адреса не знайдена"
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoadingLocation = false
            self.currentAddress = "Помилка геолокації: \(error.localizedDescription)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Authorization granted, can now get location
            isLoadingLocation = false
        }
    }
}
