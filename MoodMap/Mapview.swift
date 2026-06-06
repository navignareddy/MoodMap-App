import SwiftUI
import MapKit

struct MapView: View {
    let places: [Place]
    let mood: Mood
    var locationService: LocationService

    @State private var selectedPlace: Place?
    @State private var navigateToDetail = false
    @State private var cameraPosition: MapCameraPosition

    init(places: [Place], mood: Mood, locationService: LocationService) {
        self.places = places
        self.mood = mood
        self.locationService = locationService
        let loc = locationService.currentLocation.coordinate
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: loc,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: $selectedPlace) {
                UserAnnotation()
                ForEach(places) { place in
                    Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                        PlaceAnnotationPin(mood: mood, isSelected: selectedPlace?.id == place.id)
                            .onTapGesture { selectedPlace = place }
                    }
                    .tag(place)
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)

            if let place = selectedPlace {
                PlaceCalloutCard(place: place, mood: mood, locationService: locationService) {
                    navigateToDetail = true
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPlace)
        .navigationTitle("Map View")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToDetail) {
            if let place = selectedPlace {
                PlaceDetailView(place: place, mood: mood, locationService: locationService)
            }
        }
    }
}

struct PlaceAnnotationPin: View {
    let mood: Mood
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: mood.gradient,
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .shadow(color: mood.accentColor.opacity(0.6), radius: isSelected ? 10 : 4)
            Image(systemName: "mappin.fill")
                .font(.system(size: isSelected ? 20 : 14)).foregroundStyle(.white)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct PlaceCalloutCard: View {
    let place: Place
    let mood: Mood
    let locationService: LocationService
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: mood.gradient,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Text(mood.emoji).font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white).lineLimit(1)
                    HStack(spacing: 8) {
                        Text(place.category)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(mood.accentColor)
                        Text("·").foregroundStyle(.white.opacity(0.3))
                        Text(place.formattedDistance(from: locationService.currentLocation))
                            .font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24)).foregroundStyle(mood.accentColor)
            }
            .padding(16).background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
    }
}
