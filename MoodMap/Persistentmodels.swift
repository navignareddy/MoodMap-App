import Foundation
import SwiftData
import SwiftUI

@Model
final class MoodHistory {
    var moodRaw: String
    var placeCount: Int
    var city: String
    var date: Date

    var mood: Mood { Mood(rawValue: moodRaw) ?? .relaxed }

    init(mood: Mood, placeCount: Int, city: String, date: Date = .now) {
        self.moodRaw    = mood.rawValue
        self.placeCount = placeCount
        self.city       = city
        self.date       = date
    }
}

@Model
final class SavedPlace {
    var placeID: Int
    var name: String
    var category: String
    var latitude: Double
    var longitude: Double
    var moodRaw: String
    var savedDate: Date

    var mood: Mood { Mood(rawValue: moodRaw) ?? .relaxed }

    init(place: Place, mood: Mood, savedDate: Date = .now) {
        self.placeID   = place.id
        self.name      = place.name
        self.category  = place.category
        self.latitude  = place.latitude
        self.longitude = place.longitude
        self.moodRaw   = mood.rawValue
        self.savedDate = savedDate
    }
}

@Model
final class PlaceReview {
    var placeID: Int
    var placeName: String
    var placeCategory: String
    var moodRaw: String
    var rating: Int
    var reviewText: String
    var photoDataList: [Data]          
    var date: Date
    var latitude: Double
    var longitude: Double

    var mood: Mood { Mood(rawValue: moodRaw) ?? .relaxed }

    init(placeID: Int, placeName: String, placeCategory: String,
         mood: Mood, rating: Int, reviewText: String,
         photoDataList: [Data] = [],
         latitude: Double, longitude: Double,
         date: Date = .now) {
        self.placeID       = placeID
        self.placeName     = placeName
        self.placeCategory = placeCategory
        self.moodRaw       = mood.rawValue
        self.rating        = rating
        self.reviewText    = reviewText
        self.photoDataList = photoDataList
        self.latitude      = latitude
        self.longitude     = longitude
        self.date          = date
    }
}

@Model
final class CheckIn {
    var placeID: Int
    var placeName: String
    var placeCategory: String
    var moodRaw: String
    var latitude: Double
    var longitude: Double
    var note: String
    var date: Date

    var mood: Mood { Mood(rawValue: moodRaw) ?? .relaxed }

    init(place: Place, mood: Mood, note: String = "", date: Date = .now) {
        self.placeID       = place.id
        self.placeName     = place.name
        self.placeCategory = place.category
        self.moodRaw       = mood.rawValue
        self.latitude      = place.latitude
        self.longitude     = place.longitude
        self.note          = note
        self.date          = date
    }
}
