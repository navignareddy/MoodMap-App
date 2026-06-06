import SwiftUI
import MapKit
import SwiftData

struct PlaceDetailView: View {
    let place: Place
    let mood: Mood
    var locationService: LocationService

    @Environment(\.modelContext) private var modelContext
    @Query private var savedPlaces: [SavedPlace]
    @Query private var allReviews: [PlaceReview]
    @Query private var allCheckIns: [CheckIn]

    @State private var showSavedToast = false
    @State private var toastMessage = ""
    @State private var showWriteReview = false
    @State private var showCheckIn = false
    @State private var cameraPosition: MapCameraPosition

    init(place: Place, mood: Mood, locationService: LocationService) {
        self.place = place
        self.mood = mood
        self.locationService = locationService
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }

    private var isSaved: Bool {
        savedPlaces.contains { $0.placeID == place.id }
    }

    private var placeReviews: [PlaceReview] {
        allReviews.filter { $0.placeID == place.id }
    }

    private var averageRating: Double? {
        guard !placeReviews.isEmpty else { return nil }
        return Double(placeReviews.map(\.rating).reduce(0, +)) / Double(placeReviews.count)
    }

    private var checkInCount: Int {
        allCheckIns.filter { $0.placeID == place.id }.count
    }

    var body: some View {
        ZStack {
            Color(hex: "0F0C29").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Map(position: $cameraPosition) {
                        Annotation(place.name, coordinate: place.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: mood.gradient,
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                    .shadow(color: mood.accentColor.opacity(0.6), radius: 8)
                                Image(systemName: "mappin.fill").font(.system(size: 20)).foregroundStyle(.white)
                            }
                        }
                        UserAnnotation()
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: 240)

                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(place.name)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    HStack(spacing: 8) {
                                        Text(place.category)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(mood.accentColor)
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(mood.accentColor.opacity(0.15)).clipShape(Capsule())

                                        Label(place.formattedDistance(from: locationService.currentLocation),
                                              systemImage: "location.fill")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.55))
                                    }

                                    if let avg = averageRating {
                                        HStack(spacing: 6) {
                                            StarRow(rating: Int(avg.rounded()), size: 13)
                                            Text(String(format: "%.1f", avg))
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(Color(hex: "FBBF24"))
                                            Text("(\(placeReviews.count))")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.4))
                                        }
                                    }
                                }

                                Spacer()

                                Button {
                                    let wasAlreadySaved = isSaved
                                    if wasAlreadySaved {
                                        if let existing = savedPlaces.first(where: { $0.placeID == place.id }) {
                                            modelContext.delete(existing)
                                            try? modelContext.save()
                                        }
                                    } else {
                                        let saved = SavedPlace(place: place, mood: mood)
                                        modelContext.insert(saved)
                                        try? modelContext.save()
                                    }
                                    toastMessage = wasAlreadySaved ? "Removed from saved" : "Saved to your places ♥"
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        showSavedToast = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { showSavedToast = false }
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(isSaved ? Color(hex: "F43F5E").opacity(0.2) : Color.white.opacity(0.07))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: isSaved ? "heart.fill" : "heart")
                                            .font(.system(size: 22))
                                            .foregroundStyle(isSaved ? Color(hex: "F43F5E") : .white.opacity(0.6))
                                            .scaleEffect(isSaved ? 1.15 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSaved)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)

                        Divider().background(.white.opacity(0.1))

                        HStack(spacing: 0) {
                            ActionButton(icon: "mappin.and.ellipse", label: "Check In",
                                         color: Color(hex: "34D399"),
                                         badge: checkInCount > 0 ? "\(checkInCount)×" : nil) {
                                showCheckIn = true
                            }
                            ActionButton(icon: "star.bubble.fill", label: "Review",
                                         color: Color(hex: "FBBF24"), badge: nil) {
                                showWriteReview = true
                            }
                            NavigationLink {
                                PlaceReviewsView(place: place, mood: mood)
                            } label: {
                                ActionButtonLabel(icon: "list.star", label: "All Reviews",
                                                  color: Color(hex: "A78BFA"), badge: nil)
                            }
                            ActionButton(icon: "square.and.arrow.up", label: "Share",
                                         color: Color(hex: "60A5FA"), badge: nil) {
                                sharePlace()
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 16)

                        Divider().background(.white.opacity(0.1))

                        VStack(spacing: 0) {
                            if let hours = place.openingHours {
                                InfoRow(icon: "clock.fill", label: "Opening Hours",
                                        value: hours, color: mood.accentColor)
                                Divider().background(.white.opacity(0.08)).padding(.leading, 52)
                            }
                            if let address = place.address {
                                InfoRow(icon: "mappin.circle.fill", label: "Address",
                                        value: address, color: mood.accentColor)
                                Divider().background(.white.opacity(0.08)).padding(.leading, 52)
                            }
                            if let phone = place.phone {
                                Button {
                                    if let url = URL(string: "tel://\(phone)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    InfoRow(icon: "phone.fill", label: "Phone",
                                            value: phone, color: Color(hex: "34D399"), isLink: true)
                                }
                                Divider().background(.white.opacity(0.08)).padding(.leading, 52)
                            }
                            if let website = place.website {
                                Button {
                                    let s = website.hasPrefix("http") ? website : "https://\(website)"
                                    if let url = URL(string: s) { UIApplication.shared.open(url) }
                                } label: {
                                    InfoRow(icon: "safari.fill", label: "Website",
                                            value: website, color: Color(hex: "60A5FA"), isLink: true)
                                }
                            }
                        }
                        .padding(.top, 4)

                        if !placeReviews.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Recent Reviews", systemImage: "star.fill")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                    NavigationLink("See All") {
                                        PlaceReviewsView(place: place, mood: mood)
                                    }
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(mood.accentColor)
                                }
                                ForEach(placeReviews.prefix(2)) { review in
                                    ReviewCard(review: review)
                                }
                            }
                            .padding(.horizontal, 20).padding(.top, 20)
                        }

                        Button { openInAppleMaps() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    .font(.system(size: 22))
                                Text("Get Directions")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(LinearGradient(colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color(hex: "7C3AED").opacity(0.5), radius: 14, y: 6)
                        }
                        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
                    }
                    .background(Color(hex: "1A1730"))
                }
            }
            .ignoresSafeArea(edges: .top)

            if showSavedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: isSaved ? "heart.fill" : "heart.slash")
                            .foregroundStyle(Color(hex: "F43F5E"))
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.ultraThinMaterial).clipShape(Capsule()).shadow(radius: 10)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showWriteReview) {
            WriteReviewView(place: place, mood: mood)
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInView(place: place, mood: mood)
        }
    }

    private func openInAppleMaps() {
        let name = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "maps://?daddr=\(place.latitude),\(place.longitude)&dirflg=d&q=\(name)"
        if let url = URL(string: urlStr) { UIApplication.shared.open(url) }
    }

    private func sharePlace() {
        let text = "Check out \(place.name) (\(place.category)) on MoodMap!"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ActionButtonLabel(icon: icon, label: label, color: color, badge: badge)
        }
    }
}

struct ActionButtonLabel: View {
    let icon: String
    let label: String
    let color: Color
    let badge: String?

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
                }
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(color).clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var isLink: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4)).textCase(.uppercase).tracking(0.5)
                Text(value).font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(isLink ? color : .white.opacity(0.85)).lineLimit(2)
            }
            Spacer()
            if isLink {
                Image(systemName: "arrow.up.right").font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }
}
