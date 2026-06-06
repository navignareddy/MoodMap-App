import Foundation
import CoreLocation

enum APIError: LocalizedError {
    case invalidResponse
    case noResults
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Server busy. Please tap Try Again."
        case .noResults:       return "No places found nearby. Try a different mood."
        case .networkError:    return "Request timed out. Please check your WiFi and try again."
        case .decodingError:   return "Could not read response. Please try again."
        }
    }
}

actor PlacesAPIService {
    static let shared = PlacesAPIService()
    private init() {}

    private let baseURLs = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter"
    ]

    func fetchPlaces(for mood: Mood, near location: CLLocation) async throws -> [Place] {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let delta = 0.022
        let south = lat - delta
        let north = lat + delta
        let west  = lon - delta
        let east  = lon + delta

        let tag = mood.fastTag

        let query = "[out:json][timeout:10];node[\"\(tag.key)\"=\"\(tag.value)\"](\(south),\(west),\(north),\(east));out 25;"

        for baseURL in baseURLs {
            if let places = try? await get(query: query, baseURL: baseURL,
                                            mood: mood, ref: location) {
                if !places.isEmpty { return places }
            }
        }

        throw APIError.networkError(NSError(domain: "Timeout", code: -1))
    }

    private func get(query: String, baseURL: String,
                     mood: Mood, ref: CLLocation) async throws -> [Place] {

        var comps = URLComponents(string: baseURL)!
        comps.queryItems = [URLQueryItem(name: "data", value: query)]
        guard let url = comps.url else { throw APIError.invalidResponse }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("MoodMapApp/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else { throw APIError.invalidResponse }

        struct ORes: Decodable { let elements: [OEl] }
        struct OEl: Decodable {
            let id: Int; let lat: Double?; let lon: Double?
            let tags: [String: String]?
        }

        let decoded = try JSONDecoder().decode(ORes.self, from: data)

        let places: [Place] = decoded.elements.compactMap { el in
            guard let eLat = el.lat, let eLon = el.lon,
                  let tags = el.tags,
                  let name = tags["name"],
                  !name.trimmingCharacters(in: .whitespaces).isEmpty
            else { return nil }
            return Place(id: el.id, name: name,
                         category: mood.categoryLabel,
                         latitude: eLat, longitude: eLon, tags: tags)
        }
        .sorted {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: ref) <
            CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: ref)
        }

        if places.isEmpty { throw APIError.noResults }
        return places
    }
}
