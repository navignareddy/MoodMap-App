import SwiftUI
import UIKit
import SwiftData
import MapKit

struct SavedPlacesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedPlace.savedDate, order: .reverse) private var savedPlaces: [SavedPlace]
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedSaved: SavedPlace?

    var filtered: [SavedPlace] {
        guard !searchText.isEmpty else { return savedPlaces }
        let q = searchText.lowercased()
        return savedPlaces.filter { $0.name.lowercased().contains(q) || $0.category.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                if savedPlaces.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 52)).foregroundStyle(DS.danger.opacity(0.6))
                        Text("No saved places yet")
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                        Text("Tap the ♥ on any place to save it here.")
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textSecondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 50)
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass").foregroundStyle(DS.textMuted)
                            TextField("Search saved places…", text: $searchText)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(DS.textPrimary).tint(DS.accent)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.border, lineWidth: 1))
                        .padding(.horizontal, 16).padding(.top, 12)

                        List {
                            ForEach(filtered) { saved in
                                Button { selectedSaved = saved } label: {
                                    SavedPlaceRow(saved: saved)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                for idx in offsets { modelContext.delete(filtered[idx]) }
                                try? modelContext.save()
                            }
                        }
                        .listStyle(.plain).scrollContentBackground(.hidden)
                        .environment(\.editMode, $editMode)
                    }
                }
            }
            .navigationTitle("Saved Places")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !savedPlaces.isEmpty {
                        Button(editMode == .active ? "Done" : "Edit") {
                            withAnimation { editMode = editMode == .active ? .inactive : .active }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.accent)
                    }
                }
            }
            .sheet(item: $selectedSaved) { saved in
                SavedPlaceDetailSheet(saved: saved)
            }
        }
    }
}

struct SavedPlaceRow: View {
    let saved: SavedPlace
    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: saved.mood.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Text(saved.mood.emoji).font(.system(size: 19))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(saved.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(DS.textPrimary).lineLimit(1)
                HStack(spacing: 5) {
                    Text(saved.category).font(.system(size: 12, design: .rounded)).foregroundStyle(saved.mood.accentColor)
                    Text("·").foregroundStyle(DS.textMuted)
                    Text(saved.savedDate.relativeString).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(DS.textMuted)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct SavedPlaceDetailSheet: View {
    let saved: SavedPlace
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition

    init(saved: SavedPlace) {
        self.saved = saved
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: saved.latitude, longitude: saved.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Map(position: $cameraPosition) {
                            Annotation(saved.name, coordinate: CLLocationCoordinate2D(
                                latitude: saved.latitude, longitude: saved.longitude)) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: saved.mood.gradient,
                                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "heart.fill").font(.system(size: 16)).foregroundStyle(.white)
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .frame(height: 220)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: saved.mood.gradient,
                                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 52, height: 52)
                                    Text(saved.mood.emoji).font(.system(size: 24))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(saved.name)
                                        .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                                    HStack(spacing: 8) {
                                        Text(saved.category).font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(saved.mood.accentColor)
                                            .padding(.horizontal, 9).padding(.vertical, 3)
                                            .background(saved.mood.accentColor.opacity(0.15)).clipShape(Capsule())
                                        Text(saved.mood.rawValue).font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textSecondary)
                                    }
                                }
                                Spacer()
                            }

                            InfoRowSimple(icon: "clock.fill", label: "Saved", value: saved.savedDate.shortDateString, color: DS.accent)

                            Button {
                                let name = saved.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                let url = URL(string: "maps://?daddr=\(saved.latitude),\(saved.longitude)&dirflg=d&q=\(name)")
                                if let url { UIApplication.shared.open(url) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill").font(.system(size: 20))
                                    Text("Get Directions").font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(saved.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(DS.accent)
                }
            }
        }
    }
}

struct InfoRowSimple: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.13)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.textMuted).textCase(.uppercase).tracking(0.5)
                Text(value).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DS.textPrimary)
            }
        }
        .padding(12).background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.border, lineWidth: 1))
    }
}
