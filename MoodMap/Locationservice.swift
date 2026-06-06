import CoreLocation
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    static let fallback = CLLocation(latitude: 33.4255, longitude: -111.9400)

    private let manager = CLLocationManager()

    var currentLocation: CLLocation = LocationService.fallback
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var cityName: String = "Tempe, AZ"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        currentLocation = loc
        fetchCityName(for: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    private func fetchCityName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }
            if let pm = placemarks?.first {
                let city  = pm.locality             ?? ""
                let state = pm.administrativeArea   ?? ""
                let parts = [city, state].filter { !$0.isEmpty }
                self.cityName = parts.isEmpty ? "Unknown" : parts.joined(separator: ", ")
            }
        }
    }
}
