import SwiftUI
import SwiftData

struct RecommendationsView: View {
    let mood: Mood
    var locationService: LocationService

    @State private var vm: RecommendationsViewModel
    @State private var showMapView = false
    @State private var hasRecorded = false

    @Environment(\.modelContext) private var modelContext
    @Query private var moodHistory: [MoodHistory]
    @Query private var savedPlaces: [SavedPlace]

    init(mood: Mood, locationService: LocationService) {
        self.mood = mood
        self.locationService = locationService
        _vm = State(initialValue: RecommendationsViewModel(locationService: locationService))
    }

    var body: some View {
        ZStack {
            Color(hex: "0F0C29").ignoresSafeArea()

            switch vm.loadingState {
            case .idle:
                Color.clear
            case .loading:
                LoadingView(mood: mood)
            case .success(let places):
                if places.isEmpty {
                    EmptyStateView(mood: mood) { Task { await load() } }
                } else {
                    PlaceListView(
                        places: places, mood: mood,
                        locationService: locationService,
                        savedPlaces: savedPlaces,
                        showMapView: $showMapView
                    )
                    .onAppear { recordHistory(places: places) }
                }
            case .failure(let msg):
                ErrorView(message: msg) { Task { await load() } }
            }
        }
        .navigationTitle(mood.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showMapView = true } label: {
                    Image(systemName: "map.fill").foregroundStyle(mood.accentColor)
                }
                .disabled(vm.places.isEmpty)
            }
        }
        .navigationDestination(isPresented: $showMapView) {
            MapView(places: vm.places, mood: mood, locationService: locationService)
        }
        .task { await load() }
    }

    private func load() async {
        await vm.fetchRecommendations(for: mood)
    }

    private func recordHistory(places: [Place]) {
        guard !hasRecorded else { return }
        hasRecorded = true
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let exists = moodHistory.contains {
            $0.moodRaw == mood.rawValue && cal.startOfDay(for: $0.date) == today
        }
        if !exists {
            let entry = MoodHistory(mood: mood, placeCount: places.count, city: locationService.cityName)
            modelContext.insert(entry)
            try? modelContext.save()
        }
    }
}

struct PlaceListView: View {
    let places: [Place]
    let mood: Mood
    var locationService: LocationService
    var savedPlaces: [SavedPlace]
    @Binding var showMapView: Bool

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(mood.emoji).font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(places.count) places found")
                            .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                        Text("Sorted by distance · \(locationService.cityName)")
                            .font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Button { showMapView = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "map").font(.system(size: 12))
                            Text("Map").font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(mood.gradient[0].opacity(0.4)).clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                .background(LinearGradient(colors: mood.gradient,
                                           startPoint: .leading, endPoint: .trailing).opacity(0.3))

                LazyVStack(spacing: 12) {
                    ForEach(Array(places.enumerated()), id: \.element.id) { idx, place in
                        let isSaved = savedPlaces.contains { $0.placeID == place.id }
                        NavigationLink {
                            PlaceDetailView(place: place, mood: mood, locationService: locationService)
                        } label: {
                            PlaceRowCard(place: place, rank: idx + 1, mood: mood,
                                         locationService: locationService, isSaved: isSaved)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 30)
            }
        }
    }
}

struct PlaceRowCard: View {
    let place: Place
    let rank: Int
    let mood: Mood
    var locationService: LocationService
    let isSaved: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: mood.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 38, height: 38)
                Text("\(rank)")
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(place.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white).lineLimit(1)
                    Spacer()
                    if isSaved {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13)).foregroundStyle(Color(hex: "F43F5E"))
                    }
                }
                HStack(spacing: 8) {
                    Label(place.category, systemImage: categoryIcon(place.category))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(mood.accentColor)
                    Spacer()
                    Text(place.formattedDistance(from: locationService.currentLocation))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                if let hours = place.openingHours {
                    Text(hours).font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35)).lineLimit(1)
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08), lineWidth: 1))
    }

    func categoryIcon(_ c: String) -> String {
        switch c {
        case "Park","Garden","Common","Nature Reserve": return "leaf.fill"
        case "Café","Restaurant": return "fork.knife"
        case "Bar","Pub": return "wineglass.fill"
        case "Library": return "books.vertical.fill"
        case "Gallery","Arts Centre": return "paintpalette.fill"
        case "Theatre","Cinema": return "theatermasks.fill"
        case "Sports Centre","Climbing": return "figure.run"
        case "Spa": return "sparkles"
        case "Place of Worship": return "building.columns.fill"
        default: return "mappin.circle.fill"
        }
    }
}

struct LoadingView: View {
    let mood: Mood
    @State private var pulse = false
    @State private var dots = 0

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: mood.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .shadow(color: mood.accentColor.opacity(0.5), radius: 20)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                Text(mood.emoji).font(.system(size: 50))
            }
            VStack(spacing: 8) {
                Text("Finding \(mood.rawValue.lowercased()) spots\(String(repeating: ".", count: dots % 4))")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white).animation(nil, value: dots)
                Text("Searching nearby places…")
                    .font(.system(size: 14, design: .rounded)).foregroundStyle(.white.opacity(0.5))
            }
        }
        .onAppear {
            pulse = true
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in dots += 1 }
        }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var cleanMessage: String {
        if message.contains("<") { return "The places server is busy. Please tap Try Again." }
        if message.contains("403") { return "Server temporarily unavailable. Please tap Try Again." }
        if message.contains("429") { return "Too many requests. Please wait a moment and try again." }
        return message
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash").font(.system(size: 60)).foregroundStyle(Color(hex: "F43F5E"))
            Text("Couldn't load places")
                .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(cleanMessage).font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center).padding(.horizontal, 40)
            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white).padding(.horizontal, 32).padding(.vertical, 14)
                    .background(Color(hex: "F43F5E")).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }.padding(40)
    }
}

struct EmptyStateView: View {
    let mood: Mood
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text(mood.emoji).font(.system(size: 70))
            Text("No places found nearby")
                .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text("No \(mood.rawValue.lowercased()) spots within 5 km.")
                .font(.system(size: 14, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button(action: retry) {
                Label("Reload", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white).padding(.horizontal, 32).padding(.vertical, 14)
                    .background(mood.gradient[0]).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }.padding(40)
    }
}
