import Foundation
import CoreLocation
import Observation
import SwiftData

enum LoadingState {
    case idle
    case loading
    case success([Place])
    case failure(String)
}

@Observable
final class RecommendationsViewModel {
    var loadingState: LoadingState = .idle
    let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    @MainActor
    func fetchRecommendations(for mood: Mood) async {
        loadingState = .loading
        let location = locationService.currentLocation
        do {
            let places = try await PlacesAPIService.shared.fetchPlaces(for: mood, near: location)
            loadingState = .success(places)
        } catch {
            loadingState = .failure(error.localizedDescription)
        }
    }

    var places: [Place] {
        if case .success(let p) = loadingState { return p }
        return []
    }
}
