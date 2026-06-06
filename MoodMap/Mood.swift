import SwiftUI

enum Mood: String, CaseIterable, Codable, Hashable {
    case relaxed     = "Relaxed"
    case social      = "Social"
    case adventurous = "Adventurous"
    case focused     = "Focused"
    case creative    = "Creative"
    case mindful     = "Mindful"

    var emoji: String {
        switch self {
        case .relaxed:     return "🌿"
        case .social:      return "☕️"
        case .adventurous: return "🧗"
        case .focused:     return "📚"
        case .creative:    return "🎨"
        case .mindful:     return "🧘"
        }
    }

    var gradient: [Color] {
        switch self {
        case .relaxed:     return [Color(hex: "059669"), Color(hex: "047857")]
        case .social:      return [Color(hex: "EA580C"), Color(hex: "C2410C")]
        case .adventurous: return [Color(hex: "DC2626"), Color(hex: "B91C1C")]
        case .focused:     return [Color(hex: "4F46E5"), Color(hex: "4338CA")]
        case .creative:    return [Color(hex: "9333EA"), Color(hex: "7E22CE")]
        case .mindful:     return [Color(hex: "0D9488"), Color(hex: "0F766E")]
        }
    }

    var accentColor: Color { gradient[0] }

    var description: String {
        switch self {
        case .relaxed:     return "Peaceful spots to unwind"
        case .social:      return "Lively places to connect"
        case .adventurous: return "Exciting places to explore"
        case .focused:     return "Quiet spaces to concentrate"
        case .creative:    return "Inspiring creative spaces"
        case .mindful:     return "Calm spaces for reflection"
        }
    }

    nonisolated var overpassTags: [(key: String, value: String)] {
        switch self {
        case .relaxed:
            return [("leisure","park"),("leisure","nature_reserve"),("leisure","garden"),("leisure","common")]
        case .social:
            return [("amenity","cafe"),("amenity","restaurant"),("amenity","bar"),("amenity","pub")]
        case .adventurous:
            return [("leisure","sports_centre"),("leisure","climbing"),("tourism","attraction"),("sport","hiking")]
        case .focused:
            return [("amenity","library"),("amenity","coworking_space"),("building","university"),("amenity","college")]
        case .creative:
            return [("amenity","arts_centre"),("tourism","gallery"),("amenity","theatre"),("amenity","cinema")]
        case .mindful:
            return [("amenity","place_of_worship"),("tourism","spa"),("amenity","spa"),("natural","water")]
        }
    }

    nonisolated var primaryTags: [(key: String, value: String)] {
        switch self {
        case .relaxed:     return [("leisure","park"),("leisure","garden")]
        case .social:      return [("amenity","cafe"),("amenity","restaurant")]
        case .adventurous: return [("leisure","sports_centre"),("tourism","attraction")]
        case .focused:     return [("amenity","library"),("building","university")]
        case .creative:    return [("amenity","arts_centre"),("tourism","gallery")]
        case .mindful:     return [("amenity","place_of_worship"),("natural","water")]
        }
    }

    nonisolated var fastTag: (key: String, value: String) {
        switch self {
        case .relaxed:     return ("leisure",  "park")
        case .social:      return ("amenity",  "cafe")
        case .adventurous: return ("amenity",  "restaurant")
        case .focused:     return ("amenity",  "library")
        case .creative:    return ("amenity",  "theatre")
        case .mindful:     return ("amenity",  "place_of_worship")
        }
    }

    nonisolated var categoryLabel: String {
        switch self {
        case .relaxed:     return "Park"
        case .social:      return "Café"
        case .adventurous: return "Restaurant"
        case .focused:     return "Library"
        case .creative:    return "Theatre"
        case .mindful:     return "Place of Worship"
        }
    }
}
