import Foundation
import CoreLocation

struct Place: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let name: String
    let category: String
    let latitude: Double
    let longitude: Double
    let tags: [String: String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var website: String?      { tags["website"]      ?? tags["contact:website"] }
    var phone: String?        { tags["phone"]         ?? tags["contact:phone"]   }
    var openingHours: String? { tags["opening_hours"]                             }
    var address: String? {
        let parts = [
            tags["addr:housenumber"] ?? "",
            tags["addr:street"]      ?? "",
            tags["addr:city"]        ?? ""
        ].filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }

    func formattedDistance(from location: CLLocation) -> String {
        let m = distance(from: location)
        return m < 1000
            ? String(format: "%.0f m",  m)
            : String(format: "%.1f km", m / 1000)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Place, rhs: Place) -> Bool { lhs.id == rhs.id }
}


struct OverpassResponse: Decodable, Sendable {
    let elements: [OverpassElement]
}

struct OverpassElement: Decodable, Sendable {
    let id: Int
    let type: String
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?

    nonisolated func resolvedLatitude()  -> Double? { lat ?? center?.lat }
    nonisolated func resolvedLongitude() -> Double? { lon ?? center?.lon }
}

struct OverpassCenter: Decodable, Sendable {
    let lat: Double
    let lon: Double
}
